module multi_stage_arith_shifter (
  input [15:0] in_value,
  input [3:0] shift_amount,
  output [15:0] out_value
);
  wire [15:0] stage1, stage2;
  reg [15:0] stage3;
  
  // Two-stage shift implementation
  assign stage1 = shift_amount[3] ? {{8{in_value[15]}}, in_value[15:8]} : in_value;
  assign stage2 = shift_amount[2] ? {{4{stage1[15]}}, stage1[15:4]} : stage1;
  
  // Final stage with proper handling of the low 2 bits of shift_amount
  always @(*) begin
    case(shift_amount[1:0])
      2'b00: stage3 = stage2;
      2'b01: stage3 = {{1{stage2[15]}}, stage2[15:1]};
      2'b10: stage3 = {{2{stage2[15]}}, stage2[15:2]};
      2'b11: stage3 = {{3{stage2[15]}}, stage2[15:3]};
    endcase
  end
  
  assign out_value = stage3;
endmodule