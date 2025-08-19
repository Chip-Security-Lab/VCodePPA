//SystemVerilog
module pwm_generator_reset #(parameter COUNTER_SIZE = 8)(
  input wire clk,
  input wire rst,
  input wire [COUNTER_SIZE-1:0] duty_cycle,
  output reg pwm_out
);
  // Stage 1: Counter increment
  reg [COUNTER_SIZE-1:0] counter_stage1;
  reg [COUNTER_SIZE-1:0] duty_cycle_stage1;
  reg valid_stage1;
  
  // Stage 2: Comparison
  reg [COUNTER_SIZE-1:0] counter_stage2;
  reg [COUNTER_SIZE-1:0] duty_cycle_stage2;
  reg valid_stage2;
  reg comparison_result_stage2;
  
  // Stage 3: Output generation
  reg valid_stage3;
  
  always @(posedge clk) begin
    if (rst) begin
      // Reset all pipeline registers
      counter_stage1 <= {COUNTER_SIZE{1'b0}};
      duty_cycle_stage1 <= {COUNTER_SIZE{1'b0}};
      valid_stage1 <= 1'b0;
      
      counter_stage2 <= {COUNTER_SIZE{1'b0}};
      duty_cycle_stage2 <= {COUNTER_SIZE{1'b0}};
      valid_stage2 <= 1'b0;
      comparison_result_stage2 <= 1'b0;
      
      valid_stage3 <= 1'b0;
      pwm_out <= 1'b0;
    end else begin
      // Stage 1: Increment counter and register duty cycle
      counter_stage1 <= counter_stage1 + 1'b1;
      duty_cycle_stage1 <= duty_cycle;
      valid_stage1 <= 1'b1; // Always valid after reset
      
      // Stage 2: Pass values to next stage and perform comparison
      counter_stage2 <= counter_stage1;
      duty_cycle_stage2 <= duty_cycle_stage1;
      valid_stage2 <= valid_stage1;
      comparison_result_stage2 <= (counter_stage1 < duty_cycle_stage1);
      
      // Stage 3: Output the comparison result
      valid_stage3 <= valid_stage2;
      if (valid_stage2) begin
        pwm_out <= comparison_result_stage2;
      end
    end
  end
endmodule