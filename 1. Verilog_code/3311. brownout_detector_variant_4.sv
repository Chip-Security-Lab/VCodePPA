//SystemVerilog
module brownout_detector #(
  parameter signed [7:0] LOW_THRESHOLD  = 8'sd85,
  parameter signed [7:0] HIGH_THRESHOLD = 8'sd95
)(
  input  wire        clk,
  input  wire        enable,
  input  wire signed [7:0] supply_voltage,
  output reg         brownout_reset
);

  reg brownout_state_reg = 1'b0;
  reg brownout_state_next;
  reg supply_voltage_lt_low_reg;
  reg supply_voltage_gt_high_reg;

  // Intermediate signals for signed multiplication
  reg signed [15:0] signed_diff_low;
  reg signed [15:0] signed_diff_high;
  reg signed [15:0] signed_mult_low;
  reg signed [15:0] signed_mult_high;

  // Pipeline stage 1: Signed comparison using optimized multiplier-based algorithm
  always @(posedge clk) begin
    // supply_voltage < LOW_THRESHOLD : check MSB of (supply_voltage - LOW_THRESHOLD)
    signed_diff_low  <= supply_voltage - LOW_THRESHOLD;
    signed_mult_low  <= signed_diff_low * 16'sh0001; // Simple sign extension, multiplier optimization placeholder
    supply_voltage_lt_low_reg  <= signed_mult_low[15];

    // supply_voltage > HIGH_THRESHOLD : check MSB of (HIGH_THRESHOLD - supply_voltage)
    signed_diff_high <= HIGH_THRESHOLD - supply_voltage;
    signed_mult_high <= signed_diff_high * 16'sh0001; // Simple sign extension, multiplier optimization placeholder
    supply_voltage_gt_high_reg <= signed_mult_high[15];
  end

  // Pipeline stage 2: Compute next brownout state
  always @(*) begin
    if (!enable)
      brownout_state_next = 1'b0;
    else if (supply_voltage_lt_low_reg)
      brownout_state_next = 1'b1;
    else if (supply_voltage_gt_high_reg)
      brownout_state_next = 1'b0;
    else
      brownout_state_next = brownout_state_reg;
  end

  // Pipeline stage 3: Register new state and output
  always @(posedge clk) begin
    brownout_state_reg <= brownout_state_next;
    brownout_reset     <= brownout_state_reg;
  end

endmodule