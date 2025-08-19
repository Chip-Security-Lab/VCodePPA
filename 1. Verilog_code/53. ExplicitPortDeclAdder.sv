module verbose_adder(
  input wire [1:0] data_a,
  input wire [1:0] data_b,
  output wire [2:0] summation
);
  assign summation = data_a + data_b; //2-bit inputs
endmodule