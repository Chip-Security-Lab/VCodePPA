//SystemVerilog
module reset_duration_controller #(
  parameter MIN_DURATION = 16'd100,
  parameter MAX_DURATION = 16'd10000
)(
  input clk,
  input rst_n,
  input trigger,
  input [15:0] requested_duration,
  output reg reset_active
);

  // Pipeline registers
  reg [15:0] constrained_duration_stage1;
  reg        trigger_stage1;
  reg        reset_active_stage1;
  reg        valid_stage1;

  reg [15:0] duration_stage2;
  reg        trigger_stage2;
  reg        reset_active_stage2;
  reg        valid_stage2;

  reg [15:0] counter_stage3;
  reg        reset_active_stage3;
  reg        valid_stage3;

  wire flush;
  assign flush = !rst_n;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Stage 1
      constrained_duration_stage1 <= MIN_DURATION;
      trigger_stage1              <= 1'b0;
      reset_active_stage1         <= 1'b0;
      valid_stage1                <= 1'b0;
      // Stage 2
      duration_stage2             <= MIN_DURATION;
      trigger_stage2              <= 1'b0;
      reset_active_stage2         <= 1'b0;
      valid_stage2                <= 1'b0;
      // Stage 3
      counter_stage3              <= 16'd0;
      reset_active_stage3         <= 1'b0;
      valid_stage3                <= 1'b0;
      reset_active                <= 1'b0;
    end else begin
      // Stage 1: Duration constraint
      if (requested_duration < MIN_DURATION)
        constrained_duration_stage1 <= MIN_DURATION;
      else if (requested_duration > MAX_DURATION)
        constrained_duration_stage1 <= MAX_DURATION;
      else
        constrained_duration_stage1 <= requested_duration;

      trigger_stage1      <= trigger;
      reset_active_stage1 <= reset_active;
      valid_stage1        <= 1'b1;

      // Stage 2: Latch constrained duration, process trigger and reset_active
      duration_stage2      <= constrained_duration_stage1;
      trigger_stage2       <= trigger_stage1;
      reset_active_stage2  <= reset_active_stage1;
      valid_stage2         <= valid_stage1;

      // Stage 3: Counter and reset_active update
      if (flush) begin
        counter_stage3      <= 16'd0;
        reset_active_stage3 <= 1'b0;
        valid_stage3        <= 1'b0;
        reset_active        <= 1'b0;
      end else if (valid_stage2) begin
        // Handle reset state
        if (trigger_stage2 && !reset_active_stage2) begin
          reset_active_stage3 <= 1'b1;
          counter_stage3      <= 16'd0;
        end else if (reset_active_stage2) begin
          if (counter_stage3 >= duration_stage2 - 1) begin
            reset_active_stage3 <= 1'b0;
            counter_stage3      <= 16'd0;
          end else begin
            reset_active_stage3 <= 1'b1;
            counter_stage3      <= counter_stage3 + 16'd1;
          end
        end else begin
          reset_active_stage3 <= 1'b0;
          counter_stage3      <= counter_stage3;
        end
        valid_stage3 <= 1'b1;
        reset_active <= reset_active_stage3;
      end else begin
        valid_stage3 <= 1'b0;
        reset_active <= reset_active_stage3;
      end
    end
  end

endmodule