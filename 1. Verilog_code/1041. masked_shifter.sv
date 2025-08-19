module masked_shifter (
  input [31:0] data_in,
  input [31:0] mask,
  input [4:0] shift,
  output [31:0] data_out
);
  // Only shift bits that have corresponding 1's in mask
  wire [31:0] shifted = data_in << shift;
  assign data_out = (shifted & mask) | (data_in & ~mask);
endmodule