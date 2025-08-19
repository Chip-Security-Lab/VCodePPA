module param_even_parity #(
  parameter WIDTH = 16
)(
  input [WIDTH-1:0] data_bus,
  output parity_bit
);
  assign parity_bit = ^data_bus;
endmodule