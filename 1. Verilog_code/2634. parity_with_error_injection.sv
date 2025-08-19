module parity_with_error_injection(
  input [15:0] data_in,
  input error_inject,
  output parity
);
  assign parity = (^data_in) ^ error_inject;
endmodule