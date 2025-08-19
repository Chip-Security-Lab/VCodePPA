module adder_8 (input a, b, output sum);
  wire carry;
  assign carry = a & b;
  assign sum = (a ^ b) | carry;
endmodule