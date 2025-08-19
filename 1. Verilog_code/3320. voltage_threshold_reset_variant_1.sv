//SystemVerilog
module voltage_threshold_reset #(
  parameter THRESHOLDS = 4,
  parameter WIDTH = 8
)(
  input clk,
  input enable,
  input [WIDTH-1:0] voltage_level,
  input [THRESHOLDS-1:0][WIDTH-1:0] thresholds,
  output reg [THRESHOLDS-1:0] threshold_triggers,
  output reg reset_out
);

  integer idx;
  reg [THRESHOLDS-1:0] threshold_compare_result;

  always @(posedge clk) begin
    // Combinational threshold comparison
    for (idx = 0; idx < THRESHOLDS; idx = idx + 1) begin
      threshold_compare_result[idx] = (voltage_level < thresholds[idx]);
    end

    if (!enable) begin
      threshold_triggers <= {THRESHOLDS{1'b0}};
      reset_out <= 1'b0;
    end else begin
      threshold_triggers <= threshold_compare_result;
      reset_out <= |threshold_compare_result;
    end
  end

endmodule