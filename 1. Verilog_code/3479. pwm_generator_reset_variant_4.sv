//SystemVerilog
module pwm_generator_reset #(parameter COUNTER_SIZE = 8)(
  input clk, rst,
  input [COUNTER_SIZE-1:0] duty_cycle,
  output reg pwm_out
);
  // Counter register
  reg [COUNTER_SIZE-1:0] counter;
  
  // Pipeline stage registers
  reg [COUNTER_SIZE-1:0] duty_cycle_reg;
  
  // Compare result registers
  reg compare_result_stage1, compare_result_stage2;
  
  // Valid signals to track data through pipeline
  reg valid_stage1, valid_stage2;
  
  // Stage 1: Counter logic and direct comparison
  always @(posedge clk) begin
    if (rst) begin
      counter <= {COUNTER_SIZE{1'b0}};
      duty_cycle_reg <= {COUNTER_SIZE{1'b0}};
      compare_result_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      counter <= counter + 1'b1;
      duty_cycle_reg <= duty_cycle;
      compare_result_stage1 <= (counter < duty_cycle);
      valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Middle stage register
  always @(posedge clk) begin
    if (rst) begin
      compare_result_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      compare_result_stage2 <= compare_result_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 3: Output stage
  always @(posedge clk) begin
    if (rst) begin
      pwm_out <= 1'b0;
    end else begin
      pwm_out <= compare_result_stage2;
    end
  end
endmodule