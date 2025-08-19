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

  integer idx;

  always @(posedge clk) begin
    if (!enable) begin
      threshold_triggers <= {THRESHOLDS{1'b0}};
      reset_out <= 1'b0;
    end else begin
      for (idx = 0; idx < THRESHOLDS; idx = idx + 1) begin
        threshold_triggers[idx] <= (voltage_level < thresholds[idx]);
      end
      reset_out <= |(threshold_triggers_next_comb(voltage_level, thresholds));
    end
  end

  // Function to compute next threshold triggers (combinational)
  function automatic [THRESHOLDS-1:0] threshold_triggers_next_comb(
    input [WIDTH-1:0] voltage_level_f,
    input [THRESHOLDS-1:0][WIDTH-1:0] thresholds_f
  );
    integer j;
    begin
      for (j = 0; j < THRESHOLDS; j = j + 1) begin
        threshold_triggers_next_comb[j] = (voltage_level_f < thresholds_f[j]);
      end
    end
  endfunction

endmodule