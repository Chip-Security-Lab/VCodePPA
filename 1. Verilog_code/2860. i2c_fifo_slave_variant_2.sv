//SystemVerilog
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
    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] write_pointer, read_pointer;
    reg [2:0] fsm_state;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_count;
    
    // State definitions
    localparam IDLE_STATE      = 3'd0;
    localparam ADDR_STATE      = 3'd1;
    localparam ACK1_STATE      = 3'd2;
    localparam DATA_STATE      = 3'd3;
    localparam ACK2_STATE      = 3'd4;
    
    // I2C control signals
    reg sda_out_reg, sda_dir_reg;
    assign sda = sda_dir_reg ? sda_out_reg : 1'bz;
    
    // Start condition detection
    reg start_detected;
    reg scl_prev, sda_prev;
    
    // Pointer arithmetic
    wire [$clog2(FIFO_DEPTH):0] next_write_pointer, next_read_pointer;
    assign next_write_pointer = write_pointer + 1'b1;
    assign next_read_pointer  = read_pointer + 1'b1;

    // FIFO full/empty logic
    wire [$clog2(FIFO_DEPTH):0] pointer_diff;
    assign pointer_diff = write_pointer - read_pointer;
    wire [$clog2(FIFO_DEPTH):0] fifo_depth_value = FIFO_DEPTH[$clog2(FIFO_DEPTH):0];

    always @(*) begin
        // Optimized comparison using range check
        fifo_full  = (pointer_diff == fifo_depth_value);
        fifo_empty = (write_pointer == read_pointer);
    end

    // Start condition detection
    always @(posedge clk) begin
        scl_prev <= scl;
        sda_prev <= sda;
        start_detected <= scl && scl_prev && !sda && sda_prev;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            write_pointer <= 0;
            read_pointer  <= 0;
            fsm_state <= IDLE_STATE;
            data_valid <= 1'b0;
            data_out <= 8'h00;
            sda_dir_reg <= 1'b0;
            sda_out_reg <= 1'b0;
            bit_count <= 4'd0;
            rx_shift_reg <= 8'h00;
        end else begin
            case (fsm_state)
                IDLE_STATE: begin
                    if (start_detected) begin
                        fsm_state <= ADDR_STATE;
                        bit_count <= 4'd0;
                        rx_shift_reg <= 8'h00;
                    end
                end
                ADDR_STATE: begin
                    if (bit_count == 4'd7) begin
                        // Optimized address comparison
                        if (rx_shift_reg[7:1] == ADDR) begin
                            fsm_state <= ACK1_STATE;
                            sda_dir_reg <= 1'b1;
                            sda_out_reg <= 1'b0; // ACK
                        end else begin
                            fsm_state <= IDLE_STATE;
                        end
                    end else if (scl) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda};
                        bit_count <= bit_count + 1'b1;
                    end
                end
                ACK1_STATE: begin
                    fsm_state <= DATA_STATE;
                    bit_count <= 4'd0;
                    sda_dir_reg <= 1'b0;
                end
                DATA_STATE: begin
                    if (bit_count == 4'd7) begin
                        fsm_state <= ACK2_STATE;
                        sda_dir_reg <= 1'b1;
                        sda_out_reg <= 1'b0;
                    end else if (scl) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda};
                        bit_count <= bit_count + 1'b1;
                    end
                end
                ACK2_STATE: begin
                    fsm_state <= IDLE_STATE;
                    if (!fifo_full) begin
                        fifo_mem[write_pointer[$clog2(FIFO_DEPTH)-1:0]] <= rx_shift_reg;
                        write_pointer <= next_write_pointer;
                    end
                    sda_dir_reg <= 1'b0;
                end
                default: fsm_state <= IDLE_STATE;
            endcase

            // FIFO read logic - optimized with range check
            if (!fifo_empty && !data_valid) begin
                data_out <= fifo_mem[read_pointer[$clog2(FIFO_DEPTH)-1:0]];
                read_pointer <= next_read_pointer;
                data_valid <= 1'b1;
            end else if (data_valid) begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule