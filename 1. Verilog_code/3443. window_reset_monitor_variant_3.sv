//SystemVerilog
module window_reset_monitor #(
  parameter MIN_WINDOW = 4,
  parameter MAX_WINDOW = 12
) (
  input wire clk,
  input wire reset_pulse,
  output reg valid_reset
);
  reg [$clog2(MAX_WINDOW):0] window_counter;
  reg reset_active;
  
  // Multi-level buffering for high fanout signals
  // First level buffers
  reg reset_pulse_buf1;
  reg reset_active_buf1;
  
  // Second level buffers - split for different logic paths
  reg reset_pulse_buf2_comp;  // For comparison logic
  reg reset_pulse_buf2_ctrl;  // For control logic
  reg reset_active_buf2_ctrl; // For control path
  reg reset_active_buf2_win;  // For window logic
  
  // Buffered window counter for timing optimization
  reg [$clog2(MAX_WINDOW):0] window_counter_buf1;
  reg [$clog2(MAX_WINDOW):0] window_counter_buf2;
  
  // Intermediate comparison results to reduce critical path
  reg window_min_met, window_max_met;
  
  // First stage buffering
  always @(posedge clk) begin
    reset_pulse_buf1 <= reset_pulse;
    reset_active_buf1 <= reset_active;
    window_counter_buf1 <= window_counter;
  end
  
  // Second stage buffering with load distribution
  always @(posedge clk) begin
    reset_pulse_buf2_comp <= reset_pulse_buf1;
    reset_pulse_buf2_ctrl <= reset_pulse_buf1;
    reset_active_buf2_ctrl <= reset_active_buf1;
    reset_active_buf2_win <= reset_active_buf1;
    window_counter_buf2 <= window_counter_buf1;
  end
  
  // Pre-compute window threshold comparisons to shorten critical path
  always @(posedge clk) begin
    window_min_met <= (window_counter_buf2 >= MIN_WINDOW);
    window_max_met <= (window_counter_buf2 <= MAX_WINDOW);
  end
  
  // Main state machine logic with optimized signal paths
  always @(posedge clk) begin
    if (reset_pulse_buf2_ctrl && !reset_active_buf2_ctrl) begin
      reset_active <= 1'b1;
      window_counter <= 0;
      valid_reset <= 1'b0;
    end else if (reset_active_buf2_win) begin
      window_counter <= window_counter + 1;
      if (!reset_pulse_buf2_comp) begin
        reset_active <= 1'b0;
        valid_reset <= window_min_met && window_max_met;
      end
    end
  end
endmodule