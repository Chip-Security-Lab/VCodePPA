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
  
  always @(posedge clk) begin
    if (reset_pulse && !reset_active) begin
      reset_active <= 1'b1;
      window_counter <= 0;
      valid_reset <= 1'b0;
    end else if (reset_active) begin
      window_counter <= window_counter + 1;
      if (!reset_pulse) begin
        reset_active <= 1'b0;
        valid_reset <= (window_counter >= MIN_WINDOW) && 
                      (window_counter <= MAX_WINDOW);
      end
    end
  end
endmodule