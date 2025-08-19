//SystemVerilog
module external_reset_validator (
  input wire clk,
  input wire ext_reset,
  input wire validation_en,
  output reg valid_reset,
  output reg invalid_reset
);
  reg ext_reset_stage1;
  reg ext_reset_stage2;
  reg validation_en_reg;
  
  // First stage synchronization - moved closer to input
  always @(posedge clk) begin
    ext_reset_stage1 <= ext_reset;
    validation_en_reg <= validation_en;
  end
  
  // Second stage synchronization
  always @(posedge clk) begin
    ext_reset_stage2 <= ext_reset_stage1;
  end
  
  // Output logic stage - registers moved after combinational logic
  always @(posedge clk) begin
    valid_reset <= ext_reset_stage2 && validation_en_reg;
    invalid_reset <= ext_reset_stage2 && !validation_en_reg;
  end
endmodule