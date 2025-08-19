module adder_15 (input a, b, c_in, output sum, carry);
  assign sum = a ^ b ^ c_in;
  assign carry = (a & b) | (a & c_in) | (b & c_in);
endmodule