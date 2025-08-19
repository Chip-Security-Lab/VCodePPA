module documented_adder(/* 8-bit signed adder */
  input signed [7:0] operand_x, //Input X
  input signed [7:0] operand_y, //Input Y
  output signed [8:0] sum_result //Sum output
);
  assign sum_result = operand_x + operand_y; //Explicit comments
endmodule