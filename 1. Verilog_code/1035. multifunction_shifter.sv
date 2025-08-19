module multifunction_shifter (
  input [31:0] operand,
  input [4:0] shift_amt,
  input [1:0] operation, // 00=logical, 01=arithmetic, 10=rotate, 11=special
  output reg [31:0] shifted
);
  always @(*) begin
    case (operation)
      2'b00: shifted = operand >> shift_amt;     // Logical right
      2'b01: shifted = $signed(operand) >>> shift_amt; // Arithmetic right
      2'b10: shifted = {operand, operand} >> shift_amt; // Rotate right
      2'b11: shifted = {operand[15:0], operand[31:16]}; // Byte swap
    endcase
  end
endmodule