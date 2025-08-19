module adaptive_reset_threshold (
  input wire clk,
  input wire [7:0] signal_level,
  input wire [7:0] base_threshold,
  input wire [3:0] hysteresis,
  output reg reset_trigger
);
  reg [7:0] current_threshold;
  
  always @(posedge clk) begin
    if (signal_level < current_threshold && !reset_trigger) begin
      reset_trigger <= 1'b1;
      current_threshold <= base_threshold + hysteresis;
    end else if (signal_level > current_threshold && reset_trigger) begin
      reset_trigger <= 1'b0;
      current_threshold <= base_threshold;
    end
  end
endmodule