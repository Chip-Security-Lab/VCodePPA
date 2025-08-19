//SystemVerilog
module reset_counter_alarm #(
  parameter ALARM_THRESHOLD = 4
) (
  input wire clk,
  input wire reset_in,
  input wire clear_counter,
  output reg alarm,
  output reg [3:0] reset_count
);
  // Stage 1 registers - edge detection
  reg reset_in_stage1;
  reg reset_prev_stage1;
  reg clear_counter_stage1;
  
  // Stage 2 registers - counter logic and early alarm evaluation
  reg reset_edge_detected_stage2;
  reg clear_counter_stage2;
  reg [3:0] reset_count_stage2;
  reg alarm_stage2; // Moved alarm evaluation earlier
  
  // Output registers
  reg [3:0] reset_count_stage3;
  
  // Combined always block for all pipeline stages
  always @(posedge clk) begin
    // Stage 1: Input capture and edge detection
    reset_in_stage1 <= reset_in;
    reset_prev_stage1 <= reset_in_stage1;
    clear_counter_stage1 <= clear_counter;
    
    // Stage 2: Counter update logic with integrated alarm evaluation
    reset_edge_detected_stage2 <= reset_in_stage1 && !reset_prev_stage1;
    clear_counter_stage2 <= clear_counter_stage1;
    
    if (clear_counter_stage2)
      reset_count_stage2 <= 4'd0;
    else if (reset_edge_detected_stage2 && reset_count_stage2 < 4'hF)
      reset_count_stage2 <= reset_count_stage2 + 4'd1;
    else
      reset_count_stage2 <= reset_count_stage2;
      
    // Early alarm evaluation (moved from stage 3)
    alarm_stage2 <= (reset_count_stage2 >= ALARM_THRESHOLD);
    
    // Stage 3: Output registers
    reset_count_stage3 <= reset_count_stage2;
    reset_count <= reset_count_stage3;
    alarm <= alarm_stage2; // Use pre-computed alarm value
  end
  
endmodule