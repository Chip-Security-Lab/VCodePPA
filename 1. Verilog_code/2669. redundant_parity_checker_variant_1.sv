//SystemVerilog
module redundant_parity_checker(
  input [7:0] data_in,
  input ext_parity,
  output error_detected
);
  // Directly compute error by XORing all bits together with external parity
  // This eliminates the intermediate wire and combines operations
  assign error_detected = ^{data_in, ext_parity};
endmodule