//SystemVerilog
module pwm_generator_reset #(parameter COUNTER_SIZE = 8)(
  input wire clk, 
  input wire rst,
  input wire [COUNTER_SIZE-1:0] duty_cycle,
  output reg pwm_out
);
  
  // Pipeline stage 1 - Counter increment
  reg [COUNTER_SIZE-1:0] counter_stage1;
  reg [COUNTER_SIZE-1:0] duty_cycle_stage1;
  
  // Pipeline stage 2 - Comparison preparation
  reg [COUNTER_SIZE-1:0] counter_stage2;
  reg [COUNTER_SIZE-1:0] duty_cycle_stage2;
  
  // Pipeline stage 3 - Comparison execution
  reg compare_result_stage3;
  
  // Pipeline stage 4 - Output buffer
  reg compare_result_stage4;
  
  // Pipeline stage 5 - Final output register
  reg compare_result_stage5;
  
  // Pipeline valid signals
  reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
  
  // Stage 1: Counter increment
  always @(posedge clk) begin
    if (rst) begin
      counter_stage1 <= {COUNTER_SIZE{1'b0}};
      duty_cycle_stage1 <= {COUNTER_SIZE{1'b0}};
      valid_stage1 <= 1'b0;
    end else begin
      counter_stage1 <= counter_stage1 + 1'b1;
      duty_cycle_stage1 <= duty_cycle;
      valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Pass counter and duty cycle
  always @(posedge clk) begin
    if (rst) begin
      counter_stage2 <= {COUNTER_SIZE{1'b0}};
      duty_cycle_stage2 <= {COUNTER_SIZE{1'b0}};
      valid_stage2 <= 1'b0;
    end else begin
      counter_stage2 <= counter_stage1;
      duty_cycle_stage2 <= duty_cycle_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 3: Comparison execution
  always @(posedge clk) begin
    if (rst) begin
      compare_result_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      compare_result_stage3 <= (counter_stage2 < duty_cycle_stage2);
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Stage 4: Output buffer
  always @(posedge clk) begin
    if (rst) begin
      compare_result_stage4 <= 1'b0;
      valid_stage4 <= 1'b0;
    end else begin
      compare_result_stage4 <= compare_result_stage3;
      valid_stage4 <= valid_stage3;
    end
  end
  
  // Stage 5: Final output register
  always @(posedge clk) begin
    if (rst) begin
      compare_result_stage5 <= 1'b0;
      valid_stage5 <= 1'b0;
      pwm_out <= 1'b0;
    end else begin
      compare_result_stage5 <= compare_result_stage4;
      valid_stage5 <= valid_stage4;
      
      // Only update output when pipeline is valid
      if (valid_stage5) begin
        pwm_out <= compare_result_stage5;
      end
    end
  end
  
endmodule