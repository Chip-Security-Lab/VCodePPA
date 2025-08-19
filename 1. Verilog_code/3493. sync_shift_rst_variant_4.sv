//SystemVerilog - IEEE 1364-2005
module sync_shift_rst #(parameter DEPTH=4) (
    input wire clk,
    input wire rst,
    input wire serial_in,
    output reg [DEPTH-1:0] shift_reg
);

// Buffer registers to reduce fanout
reg [DEPTH-1:0] shift_reg_buf1;
reg [DEPTH-1:0] shift_reg_buf2;

// Main shift register with reduced fanout
always @(posedge clk)
    shift_reg <= rst ? {DEPTH{1'b0}} : {shift_reg_buf2[DEPTH-2:0], serial_in};

// First level buffer to distribute load
always @(posedge clk)
    shift_reg_buf1 <= rst ? {DEPTH{1'b0}} : shift_reg;

// Second level buffer to further distribute load
always @(posedge clk)
    shift_reg_buf2 <= rst ? {DEPTH{1'b0}} : shift_reg_buf1;

endmodule