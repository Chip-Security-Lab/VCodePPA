module bidir_parity_module(
  input [15:0] data,
  input even_odd_sel,  // 0-even, 1-odd
  output parity_out
);
  assign parity_out = even_odd_sel ? ~(^data) : ^data;
endmodule