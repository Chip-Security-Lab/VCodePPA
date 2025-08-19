//SystemVerilog
module temp_reset_detector #(
  parameter TEMP_THRESHOLD = 8'd80, // 80°C threshold
  parameter HYSTERESIS = 8'd5
)(
  input  wire        clk,
  input  wire        enable,
  input  wire [7:0]  temperature, // Temperature in °C
  output reg         temp_alarm,
  output reg         reset_out
);
  reg overtemp_state = 1'b0;
  reg [1:0] alarm_count = 2'b00;

  wire temp_above_threshold   = (temperature > TEMP_THRESHOLD);
  wire temp_below_hyst_range = (temperature < (TEMP_THRESHOLD - HYSTERESIS));
  wire temp_in_hyst_range    = !(temp_above_threshold | temp_below_hyst_range);

  always @(posedge clk) begin
    if (!enable) begin
      overtemp_state <= 1'b0;
      alarm_count    <= 2'b00;
      temp_alarm     <= 1'b0;
      reset_out      <= 1'b0;
    end else begin
      // Optimized overtemp_state update with fewer comparisons
      case ({temp_above_threshold, temp_below_hyst_range})
        2'b10: overtemp_state <= 1'b1;
        2'b01: overtemp_state <= 1'b0;
        default: overtemp_state <= overtemp_state;
      endcase

      temp_alarm <= overtemp_state;

      // Optimized alarm_count update using conditional increment and saturation
      if (overtemp_state) begin
        alarm_count <= (alarm_count == 2'b11) ? 2'b11 : alarm_count + 1'b1;
      end else begin
        alarm_count <= 2'b00;
      end

      // Optimized reset_out assignment
      reset_out <= (alarm_count == 2'b11);
    end
  end
endmodule