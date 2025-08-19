module testable_parity_gen(
  input [7:0] data,
  input test_mode,
  input test_parity,
  output parity_bit
);
  assign parity_bit = test_mode ? test_parity : ^data;
endmodule