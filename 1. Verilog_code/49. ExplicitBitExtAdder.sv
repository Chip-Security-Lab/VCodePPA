module bitwise_add(
  input [2:0] a, b,
  output [3:0] total
);
  assign total = {1'b0,a} + {1'b0,b}; //3-bit + carry
endmodule