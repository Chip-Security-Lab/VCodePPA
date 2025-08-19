//SystemVerilog
module reset_delay_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_stuck_error
);
  // Parameters for configurable timeout
  localparam TIMEOUT_VALUE = 16'hFFFF;
  
  // Pipeline stage 1: Counter management
  reg [15:0] delay_counter_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2: Threshold comparison
  reg [15:0] delay_counter_stage2;
  reg counter_approaching_max_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3: Error detection and latching
  reg counter_max_stage3;
  reg valid_stage3;
  
  // Stage 1: Reset counter tracking
  always @(posedge clk or negedge reset_n) begin
    if (reset_n) begin
      // Normal operation - reset the counter and control signals
      delay_counter_stage1 <= 16'h0000;
      valid_stage1 <= 1'b0;
    end
    else begin
      // During reset assertion - increment counter
      delay_counter_stage1 <= delay_counter_stage1 + 1'b1;
      valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Threshold comparison
  always @(posedge clk or negedge reset_n) begin
    if (reset_n) begin
      // Clear pipeline registers
      delay_counter_stage2 <= 16'h0000;
      counter_approaching_max_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end
    else begin
      // Pass data through pipeline
      delay_counter_stage2 <= delay_counter_stage1;
      counter_approaching_max_stage2 <= (delay_counter_stage1 >= (TIMEOUT_VALUE - 16'h0002)); // Early warning
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 3: Error detection and latching
  always @(posedge clk or negedge reset_n) begin
    if (reset_n) begin
      // Clear error and pipeline registers
      counter_max_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      reset_stuck_error <= 1'b0;
    end
    else begin
      // Pass data through pipeline
      counter_max_stage3 <= (delay_counter_stage2 == TIMEOUT_VALUE);
      valid_stage3 <= valid_stage2;
      
      // Generate and latch error signal
      if (valid_stage3 && counter_max_stage3)
        reset_stuck_error <= 1'b1;
      // Error remains latched until reset_n is asserted
    end
  end
endmodule