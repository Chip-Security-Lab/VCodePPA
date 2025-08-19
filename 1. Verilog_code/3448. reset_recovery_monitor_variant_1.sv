//SystemVerilog
module reset_recovery_monitor #(
  parameter MIN_STABLE_CYCLES = 16
) (
  input  wire clk,           // System clock
  input  wire reset_n,       // Active low reset
  output wire system_stable  // System stability indicator
);
  
  // Constants and parameters
  localparam COUNTER_WIDTH = $clog2(MIN_STABLE_CYCLES);
  
  //===================================================
  // Primary Data Path: Reset Recovery Pipeline
  //===================================================
  
  // Stage 1: Counter Control and Increment
  reg [COUNTER_WIDTH-1:0] counter_stage1_r;
  wire counter_increment_en;
  wire [COUNTER_WIDTH-1:0] counter_next;
  
  // Stage 2: Threshold Detection
  reg counter_threshold_met_stage2_r;
  
  // Stage 3: Stability Output
  reg system_stable_stage3_r;
  
  //===================================================
  // Data Path Logic Implementation
  //===================================================
  
  // Counter control logic (enable increment when below threshold)
  assign counter_increment_en = (counter_stage1_r < MIN_STABLE_CYCLES-1);
  
  // Counter next value calculation
  assign counter_next = counter_stage1_r + 1'b1;
  
  // Stage 1: Counter pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      counter_stage1_r <= {COUNTER_WIDTH{1'b0}};
    end else if (counter_increment_en) begin
      counter_stage1_r <= counter_next;
    end
  end
  
  // Stage 2: Threshold detection pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      counter_threshold_met_stage2_r <= 1'b0;
    end else begin
      counter_threshold_met_stage2_r <= (counter_stage1_r == MIN_STABLE_CYCLES-1);
    end
  end
  
  // Stage 3: Stability output pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      system_stable_stage3_r <= 1'b0;
    end else begin
      system_stable_stage3_r <= counter_threshold_met_stage2_r;
    end
  end

  // Connect stability register to output
  assign system_stable = system_stable_stage3_r;
  
endmodule