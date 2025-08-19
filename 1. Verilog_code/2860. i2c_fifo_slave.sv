module i2c_fifo_slave #(
    parameter FIFO_DEPTH = 4,
    parameter ADDR = 7'h42
)(
    input clk, rstn,
    output reg fifo_full, fifo_empty,
    output reg [7:0] data_out,
    output reg data_valid,
    inout sda, scl
);
    reg [7:0] fifo [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
    reg [2:0] state;
    reg [7:0] rx_byte;
    reg [3:0] bit_idx;
    
    assign fifo_full = (wr_ptr - rd_ptr) == FIFO_DEPTH;
    assign fifo_empty = (wr_ptr == rd_ptr);
    
    // State definitions - 修改状态名称避免与参数冲突
    localparam IDLE = 3'd0;
    localparam ADDR_STATE = 3'd1; // 改名避免与parameter ADDR冲突
    localparam ACK1 = 3'd2;
    localparam DATA = 3'd3;
    localparam ACK2 = 3'd4;
    
    // I2C control signals
    reg sda_out, sda_dir;
    assign sda = sda_dir ? sda_out : 1'bz;
    
    // Start condition detection
    reg start_detected;
    reg scl_prev, sda_prev;
    
    always @(posedge clk) begin
        scl_prev <= scl;
        sda_prev <= sda;
        start_detected <= scl && scl_prev && !sda && sda_prev;
    end
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_ptr <= 0; rd_ptr <= 0;
            state <= IDLE;
            data_valid <= 1'b0;
            data_out <= 8'h00;
            sda_dir <= 1'b0; // 添加未初始化的输出
            sda_out <= 1'b0; // 添加未初始化的输出
            bit_idx <= 4'd0; // 添加未初始化的寄存器
            rx_byte <= 8'h00; // 添加未初始化的寄存器
        end else begin
            case (state)
                IDLE: if (start_detected) begin
                    state <= ADDR_STATE; // 使用重命名的状态
                    bit_idx <= 4'd0;
                    rx_byte <= 8'h00;
                end
                ADDR_STATE: if (bit_idx == 4'd7) begin // 使用重命名的状态
                    if (rx_byte[7:1] == ADDR) begin
                        state <= ACK1;
                        sda_dir <= 1'b1;
                        sda_out <= 1'b0; // ACK
                    end else
                        state <= IDLE;
                end else if (scl) begin
                    rx_byte <= {rx_byte[6:0], sda};
                    bit_idx <= bit_idx + 1;
                end
                ACK1: begin
                    state <= DATA;
                    bit_idx <= 4'd0;
                    sda_dir <= 1'b0; // Release SDA
                end
                DATA: if (bit_idx == 4'd7) begin
                    state <= ACK2;
                    sda_dir <= 1'b1;
                    sda_out <= 1'b0; // ACK
                end else if (scl) begin
                    rx_byte <= {rx_byte[6:0], sda};
                    bit_idx <= bit_idx + 1;
                end
                ACK2: begin
                    state <= IDLE;
                    // Store data in FIFO if not full
                    if (!fifo_full) begin
                        fifo[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= rx_byte;
                        wr_ptr <= wr_ptr + 1;
                    end
                    sda_dir <= 1'b0; // Release SDA
                end
                default: state <= IDLE;
            endcase
            
            // Read from FIFO
            if (!fifo_empty && !data_valid) begin
                data_out <= fifo[rd_ptr[$clog2(FIFO_DEPTH)-1:0]];
                rd_ptr <= rd_ptr + 1;
                data_valid <= 1'b1;
            end else if (data_valid) begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule