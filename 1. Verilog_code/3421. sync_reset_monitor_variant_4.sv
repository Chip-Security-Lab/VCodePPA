//SystemVerilog
module sync_reset_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_stable
);
  // Input sample registers - increased pipeline depth
  reg reset_n_stage1;
  reg reset_n_stage2;
  
  // Shift registers - increased pipeline depth
  reg reset_shift_stage1;
  reg reset_shift_stage2;
  reg reset_shift_stage3;
  reg reset_shift_stage4;
  reg reset_shift_stage5;
  reg reset_shift_stage6;
  
  // Valid signal pipeline
  reg valid_stage1;
  reg valid_stage2;
  reg valid_stage3;
  
  // Intermediate combination results
  reg reset_and_stage1;
  reg reset_and_stage2;
  
  // Sample the input with multiple pipeline stages
  always @(posedge clk) begin
    reset_n_stage1 <= reset_n;
    reset_n_stage2 <= reset_n_stage1;
  end
  
  // Implement deeper shift register chain 
  always @(posedge clk) begin
    reset_shift_stage1 <= reset_n_stage2;
    reset_shift_stage2 <= reset_shift_stage1;
    reset_shift_stage3 <= reset_shift_stage2;
    reset_shift_stage4 <= reset_shift_stage3;
    reset_shift_stage5 <= reset_shift_stage4;
    reset_shift_stage6 <= reset_shift_stage5;
  end
  
  // Multi-stage valid logic
  always @(posedge clk) begin
    // Becomes valid after more cycles for increased stability
    valid_stage1 <= (valid_stage1) ? 1'b1 : reset_shift_stage4;
    valid_stage2 <= valid_stage1;
    valid_stage3 <= valid_stage2;
  end
  
  // Break down the AND operation into multiple stages to reduce logic depth
  always @(posedge clk) begin
    // First stage of AND operations
    reset_and_stage1 <= reset_shift_stage3 & reset_shift_stage4;
    
    // Second stage of AND operations
    reset_and_stage2 <= reset_and_stage1 & reset_shift_stage5 & reset_shift_stage6;
    
    // Generate stable reset output
    reset_stable <= valid_stage3 ? reset_and_stage2 : 1'b0;
  end
endmodule