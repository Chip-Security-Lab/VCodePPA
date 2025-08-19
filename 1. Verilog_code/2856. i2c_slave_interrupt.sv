module i2c_slave_interrupt(
    input clk, reset,
    input [6:0] device_addr,
    output reg [7:0] data_out,
    output reg data_ready,
    output reg addr_match_int, data_int, error_int,
    inout sda, scl
);
    reg [3:0] bit_count;
    reg [2:0] state;
    reg [7:0] rx_shift_reg;
    reg sda_in_r, scl_in_r, sda_out;
    
    wire start_condition = scl_in_r && sda_in_r && !sda;
    wire stop_condition = scl_in_r && !sda_in_r && sda;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 3'b000; data_int <= 1'b0;
        end else case (state)
            3'b000: if (start_condition) state <= 3'b001;
            3'b011: begin data_out <= rx_shift_reg; data_int <= 1'b1; end
        endcase
    end
endmodule