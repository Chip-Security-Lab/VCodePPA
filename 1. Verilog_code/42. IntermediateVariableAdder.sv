module adder_10 (input a, b, output sum);
  wire temp_sum;
  assign temp_sum = a + b;
  assign sum = temp_sum;
endmodule