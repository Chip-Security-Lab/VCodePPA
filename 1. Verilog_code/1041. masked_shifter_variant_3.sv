//SystemVerilog
module masked_shifter (
  input  wire [31:0] data_in,
  input  wire [31:0] mask,
  input  wire [4:0]  shift,
  output wire [31:0] data_out
);
  wire shift_zero_flag = (shift == 5'd0);
  wire [31:0] shifted_data = data_in << shift;
  wire [31:0] muxed_data = (data_in & {32{shift_zero_flag}}) | (shifted_data & {32{~shift_zero_flag}});
  assign data_out = (muxed_data & mask) | (data_in & ~mask);
endmodule