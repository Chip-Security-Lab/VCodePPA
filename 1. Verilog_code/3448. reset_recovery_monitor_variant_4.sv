//SystemVerilog
module reset_recovery_monitor #(
  parameter MIN_STABLE_CYCLES = 16
) (
  input wire clk,
  input wire reset_n,
  output reg system_stable
);
  // Stage 1: Counter tracking  
  reg [$clog2(MIN_STABLE_CYCLES)-1:0] stable_counter_stage1;
  reg valid_stage1;
  wire counter_at_target_stage1 = (stable_counter_stage1 == MIN_STABLE_CYCLES-1);
  wire counter_not_at_target_stage1 = (stable_counter_stage1 < MIN_STABLE_CYCLES-1);
  
  // Stage 2: Counter update decision
  reg [$clog2(MIN_STABLE_CYCLES)-1:0] stable_counter_stage2;
  reg counter_at_target_stage2;
  reg counter_not_at_target_stage2;
  reg valid_stage2;
  
  // Stage 3: System stability determination
  reg [$clog2(MIN_STABLE_CYCLES)-1:0] stable_counter_stage3;
  reg counter_at_target_stage3;
  reg valid_stage3;
  
  // Pipeline Stage 1: Counter tracking
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_counter_stage1 <= {$clog2(MIN_STABLE_CYCLES){1'b0}};
      valid_stage1 <= 1'b0;
    end else begin
      stable_counter_stage1 <= counter_not_at_target_stage1 ? 
                              stable_counter_stage1 + 1'b1 : stable_counter_stage1;
      valid_stage1 <= 1'b1;
    end
  end
  
  // Pipeline Stage 2: Counter update decision
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_counter_stage2 <= {$clog2(MIN_STABLE_CYCLES){1'b0}};
      counter_at_target_stage2 <= 1'b0;
      counter_not_at_target_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      stable_counter_stage2 <= stable_counter_stage1;
      counter_at_target_stage2 <= counter_at_target_stage1;
      counter_not_at_target_stage2 <= counter_not_at_target_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Pipeline Stage 3: System stability determination
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_counter_stage3 <= {$clog2(MIN_STABLE_CYCLES){1'b0}};
      counter_at_target_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      system_stable <= 1'b0;
    end else begin
      stable_counter_stage3 <= stable_counter_stage2;
      counter_at_target_stage3 <= counter_at_target_stage2;
      valid_stage3 <= valid_stage2;
      system_stable <= valid_stage3 && counter_at_target_stage3;
    end
  end
endmodule