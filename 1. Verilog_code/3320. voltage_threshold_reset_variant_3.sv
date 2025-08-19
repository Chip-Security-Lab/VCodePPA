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

  // Intermediate comparison results
  wire [THRESHOLDS-1:0] trigger_next_unbuf;
  // Buffered versions of trigger_next to reduce fanout
  reg  [THRESHOLDS-1:0] trigger_next_buf;
  // Buffered index signals to drive threshold comparison
  reg  [WIDTH-1:0] voltage_level_buf;
  reg  [THRESHOLDS-1:0][WIDTH-1:0] thresholds_buf;

  integer idx;

  // Buffering voltage_level and thresholds to balance fanout for idx
  always @(posedge clk) begin
    voltage_level_buf <= voltage_level;
    for (idx = 0; idx < THRESHOLDS; idx = idx + 1) begin
      thresholds_buf[idx] <= thresholds[idx];
    end
  end

  genvar gidx;
  generate
    for (gidx = 0; gidx < THRESHOLDS; gidx = gidx + 1) begin : gen_threshold_compare
      assign trigger_next_unbuf[gidx] = (voltage_level_buf < thresholds_buf[gidx]);
    end
  endgenerate

  // Buffering trigger_next to reduce fanout to outputs
  always @(posedge clk) begin
    trigger_next_buf <= trigger_next_unbuf;
  end

  always @(posedge clk) begin
    if (!enable) begin
      threshold_triggers <= {THRESHOLDS{1'b0}};
      reset_out <= 1'b0;
    end else begin
      threshold_triggers <= trigger_next_buf;
      reset_out <= |trigger_next_buf;
    end
  end

endmodule