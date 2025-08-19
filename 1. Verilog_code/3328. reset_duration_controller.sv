module reset_duration_controller #(
  parameter MIN_DURATION = 16'd100,
  parameter MAX_DURATION = 16'd10000
)(
  input clk, trigger,
  input [15:0] requested_duration,
  output reg reset_active
);
  reg [15:0] counter = 16'd0;
  reg [15:0] actual_duration;
  
  always @(posedge clk) begin
    // Calculate constrained duration
    if (requested_duration < MIN_DURATION)
      actual_duration <= MIN_DURATION;
    else if (requested_duration > MAX_DURATION)
      actual_duration <= MAX_DURATION;
    else
      actual_duration <= requested_duration;
      
    // Handle reset state
    if (trigger && !reset_active) begin
      reset_active <= 1'b1;
      counter <= 16'd0;
    end else if (reset_active) begin
      if (counter >= actual_duration - 1)
        reset_active <= 1'b0;
      else
        counter <= counter + 16'd1;
    end
  end
endmodule