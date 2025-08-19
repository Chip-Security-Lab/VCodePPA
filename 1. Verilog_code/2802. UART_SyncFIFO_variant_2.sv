//SystemVerilog
module UART_SyncFIFO #(
    parameter FIFO_DEPTH = 64,
    parameter FIFO_WIDTH = 10  // 8数据+1奇偶+1状态
)(
    input  wire             clk,       
    input  wire             rx_clk,    
    input  wire             rx_valid,  
    input  wire [7:0]       rx_data,   
    input  wire             frame_err, 
    input  wire             parity_err,
    output wire             fifo_full,
    output wire             fifo_empty,
    input  wire             fifo_flush 
);
    // 精确水位指示
    localparam FIFO_THRESH = FIFO_DEPTH - 4;

    reg [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [7:0] write_pointer, read_pointer;
    wire [7:0] read_pointer_sync;

    // 前向寄存器重定时：将rx_valid、rx_data、frame_err、parity_err寄存器向后推到组合逻辑后
    reg        rx_valid_reg;
    reg [7:0]  rx_data_reg;
    reg        frame_err_reg;
    reg        parity_err_reg;

    always @(posedge clk) begin
        if (fifo_flush) begin
            rx_valid_reg   <= 1'b0;
            rx_data_reg    <= 8'd0;
            frame_err_reg  <= 1'b0;
            parity_err_reg <= 1'b0;
        end else begin
            rx_valid_reg   <= rx_valid;
            rx_data_reg    <= rx_data;
            frame_err_reg  <= frame_err;
            parity_err_reg <= parity_err;
        end
    end

    // 写入数据打包优化，移到寄存器后
    wire [FIFO_WIDTH-1:0] fifo_input_data;
    assign fifo_input_data = {frame_err_reg, parity_err_reg, rx_data_reg};

    // 写入控制逻辑，寄存器已移到组合逻辑后
    always @(posedge clk) begin
        if (fifo_flush) begin
            write_pointer <= 8'd0;
        end else if (rx_valid_reg && !fifo_full) begin
            fifo_mem[write_pointer] <= fifo_input_data;
            write_pointer <= write_pointer + 1'b1;
        end
    end

    // 读取控制逻辑
    always @(posedge rx_clk) begin
        if (fifo_flush) begin
            read_pointer <= 8'd0;
        end else if (!fifo_empty) begin
            // 读取FIFO逻辑 - 在真实实现中会有数据输出
            read_pointer <= read_pointer + 1'b1;
        end
    end

    // 读指针跨时钟同步（两级寄存器同步器）
    reg [7:0] read_pointer_sync_stage1;
    reg [7:0] read_pointer_sync_stage2;

    always @(posedge clk) begin
        read_pointer_sync_stage1 <= read_pointer;
        read_pointer_sync_stage2 <= read_pointer_sync_stage1;
    end

    assign read_pointer_sync = read_pointer_sync_stage2;

    // 优化路径-均衡的FIFO状态计算
    wire [8:0] pointer_diff;
    assign pointer_diff = {1'b0, write_pointer} - {1'b0, read_pointer_sync};

    // 使用中间信号减少组合逻辑级数
    wire fifo_full_cond;
    assign fifo_full_cond = (pointer_diff[8] == 1'b0) && (pointer_diff[7:0] >= FIFO_DEPTH[7:0]);

    assign fifo_full  = fifo_full_cond;
    assign fifo_empty = (write_pointer == read_pointer);

endmodule