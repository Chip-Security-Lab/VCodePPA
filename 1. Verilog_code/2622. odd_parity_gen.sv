module odd_parity_gen(
  input [7:0] data_input,
  output odd_parity
);
  assign odd_parity = ~(^data_input);
endmodule