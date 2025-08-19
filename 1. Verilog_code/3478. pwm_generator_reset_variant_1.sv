//SystemVerilog
module pwm_generator_reset #(parameter COUNTER_SIZE = 8)(
  input clk, rst,
  input [COUNTER_SIZE-1:0] duty_cycle,
  output reg pwm_out
);
  // Counter pipeline registers
  reg [COUNTER_SIZE-1:0] counter_stage1;
  reg [COUNTER_SIZE/2-1:0] counter_upper_stage1;
  reg [COUNTER_SIZE/2-1:0] counter_lower_stage1;
  reg counter_carry_stage1;
  reg [COUNTER_SIZE-1:0] counter_stage2;
  
  // Duty cycle pipeline registers
  reg [COUNTER_SIZE-1:0] duty_cycle_stage1;
  reg [COUNTER_SIZE-1:0] duty_cycle_stage2;
  reg [COUNTER_SIZE-1:0] duty_cycle_stage3;
  
  // Comparison pipeline registers
  reg compare_partial_lower_stage2;
  reg compare_partial_upper_stage2;
  reg compare_result_stage3;
  reg compare_result_stage4;
  
  // Pipeline stage 1: Counter lower bits increment and duty_cycle latch
  always @(posedge clk) begin
    if (rst) begin
      counter_lower_stage1 <= {(COUNTER_SIZE/2){1'b0}};
      counter_upper_stage1 <= {(COUNTER_SIZE/2){1'b0}};
      counter_carry_stage1 <= 1'b0;
      duty_cycle_stage1 <= {COUNTER_SIZE{1'b0}};
    end else begin
      // Split counter increment into two parts for better timing
      {counter_carry_stage1, counter_lower_stage1} <= counter_lower_stage1 + 1'b1;
      counter_upper_stage1 <= counter_upper_stage1 + (counter_carry_stage1 ? 1'b1 : 1'b0);
      duty_cycle_stage1 <= duty_cycle;
    end
  end
  
  // Pipeline stage 2: Assemble counter and partial comparisons
  always @(posedge clk) begin
    if (rst) begin
      counter_stage2 <= {COUNTER_SIZE{1'b0}};
      duty_cycle_stage2 <= {COUNTER_SIZE{1'b0}};
      compare_partial_lower_stage2 <= 1'b0;
      compare_partial_upper_stage2 <= 1'b0;
    end else begin
      counter_stage2 <= {counter_upper_stage1, counter_lower_stage1};
      duty_cycle_stage2 <= duty_cycle_stage1;
      
      // Split comparison into two parts for better timing
      compare_partial_lower_stage2 <= (counter_lower_stage1 < duty_cycle_stage1[COUNTER_SIZE/2-1:0]);
      compare_partial_upper_stage2 <= (counter_upper_stage1 < duty_cycle_stage1[COUNTER_SIZE-1:COUNTER_SIZE/2]);
    end
  end
  
  // Pipeline stage 3: Final comparison result
  always @(posedge clk) begin
    if (rst) begin
      compare_result_stage3 <= 1'b0;
      duty_cycle_stage3 <= {COUNTER_SIZE{1'b0}};
    end else begin
      // Combine partial comparisons
      compare_result_stage3 <= compare_partial_upper_stage2 || 
                              (compare_partial_upper_stage2 == duty_cycle_stage2[COUNTER_SIZE-1:COUNTER_SIZE/2] && 
                               compare_partial_lower_stage2);
      duty_cycle_stage3 <= duty_cycle_stage2;
    end
  end
  
  // Pipeline stage 4: Intermediate result register
  always @(posedge clk) begin
    if (rst) begin
      compare_result_stage4 <= 1'b0;
    end else begin
      compare_result_stage4 <= compare_result_stage3;
    end
  end
  
  // Pipeline stage 5: Output register
  always @(posedge clk) begin
    if (rst) begin
      pwm_out <= 1'b0;
    end else begin
      pwm_out <= compare_result_stage4;
    end
  end
endmodule