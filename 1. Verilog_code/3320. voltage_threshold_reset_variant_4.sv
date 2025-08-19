//SystemVerilog
module voltage_threshold_reset #(
  parameter THRESHOLDS = 4,
  parameter WIDTH = 8
)(
  input  wire                  clk,
  input  wire                  enable,
  input  wire [WIDTH-1:0]      voltage_level,
  input  wire [THRESHOLDS-1:0][WIDTH-1:0] thresholds,
  output reg  [THRESHOLDS-1:0] threshold_triggers,
  output reg                   reset_out
);
  integer i;
  reg [THRESHOLDS-1:0] next_triggers;
  reg next_reset_out;

  always @(*) begin
    next_triggers = {THRESHOLDS{1'b0}};
    for (i = 0; i < THRESHOLDS; i = i + 1) begin
      next_triggers[i] = enable & (voltage_level < thresholds[i]);
    end
    next_reset_out = |next_triggers;
  end

  always @(posedge clk) begin
    threshold_triggers <= next_triggers;
    reset_out <= next_reset_out;
  end

endmodule