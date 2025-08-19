module voltage_threshold_reset #(
  parameter THRESHOLDS = 4,
  parameter WIDTH = 8
)(
  input clk, enable,
  input [WIDTH-1:0] voltage_level,
  input [THRESHOLDS-1:0][WIDTH-1:0] thresholds,
  output reg [THRESHOLDS-1:0] threshold_triggers,
  output reg reset_out
);
  integer i;
  
  always @(posedge clk) begin
    if (!enable) begin
      threshold_triggers <= {THRESHOLDS{1'b0}};
      reset_out <= 1'b0;
    end else begin
      for (i = 0; i < THRESHOLDS; i = i + 1)
        threshold_triggers[i] <= (voltage_level < thresholds[i]);
      
      reset_out <= |threshold_triggers;
    end
  end
endmodule