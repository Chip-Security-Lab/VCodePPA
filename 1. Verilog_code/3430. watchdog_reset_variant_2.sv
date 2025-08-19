//SystemVerilog
module watchdog_reset #(
  parameter TIMEOUT = 1024
) (
  input wire clk,
  input wire watchdog_kick,
  input wire rst_n,
  output reg watchdog_rst
);
  // Define pipeline stages
  localparam PIPELINE_STAGES = 3;
  
  // Counter divided across pipeline stages
  reg [$clog2(TIMEOUT)-1:0] counter_stage1;
  reg [$clog2(TIMEOUT)-1:0] counter_stage2;
  reg [$clog2(TIMEOUT)-1:0] counter_stage3;
  
  // Pipeline control signals
  reg kick_stage1, kick_stage2, kick_stage3;
  reg valid_stage1, valid_stage2, valid_stage3;
  reg threshold_check_stage2, threshold_check_stage3;

  // Stage 1: Synchronize input kick signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      kick_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      kick_stage1 <= watchdog_kick;
      valid_stage1 <= 1'b1;
    end
  end

  // Stage 1: Counter update logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage1 <= 0;
    end else begin
      if (watchdog_kick)
        counter_stage1 <= 0;
      else if (counter_stage3 < TIMEOUT-1)
        counter_stage1 <= counter_stage3 + 1;
      else
        counter_stage1 <= counter_stage3;
    end
  end
  
  // Stage 2: Pipeline control signal propagation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      kick_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      kick_stage2 <= kick_stage1;
      valid_stage2 <= valid_stage1;
    end
  end

  // Stage 2: Counter value and threshold check
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage2 <= 0;
      threshold_check_stage2 <= 1'b0;
    end else begin
      counter_stage2 <= counter_stage1;
      // Pre-compute threshold check
      threshold_check_stage2 <= (counter_stage1 == TIMEOUT-1);
    end
  end
  
  // Stage 3: Pipeline control signal propagation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      kick_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      counter_stage3 <= 0;
    end else begin
      kick_stage3 <= kick_stage2;
      valid_stage3 <= valid_stage2;
      counter_stage3 <= counter_stage2;
    end
  end

  // Stage 3: Threshold check propagation and reset generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      threshold_check_stage3 <= 1'b0;
      watchdog_rst <= 1'b0;
    end else begin
      threshold_check_stage3 <= threshold_check_stage2;
      
      // Generate reset output
      if (valid_stage3)
        watchdog_rst <= threshold_check_stage3;
    end
  end
endmodule