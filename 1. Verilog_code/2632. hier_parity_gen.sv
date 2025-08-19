module hier_parity_gen(
  input [31:0] wide_data,
  output parity
);
  wire p1, p2;
  assign p1 = ^wide_data[15:0];
  assign p2 = ^wide_data[31:16];
  assign parity = p1 ^ p2;
endmodule