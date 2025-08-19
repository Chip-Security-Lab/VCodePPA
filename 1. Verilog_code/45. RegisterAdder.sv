module adder_13 (input a, b, output sum);
  reg output_reg;
  always @(*) begin
    output_reg = a + b;
  end
  assign sum = output_reg;
endmodule