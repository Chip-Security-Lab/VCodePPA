module alias_add(
  input [5:0] primary, secondary,
  output [6:0] aggregate
);
  wire [5:0] operand_A = primary;
  wire [5:0] operand_B = secondary;
  assign aggregate = operand_A + operand_B; //Variable renaming
endmodule