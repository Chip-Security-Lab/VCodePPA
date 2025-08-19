//SystemVerilog
module temp_reset_detector #(
  parameter TEMP_THRESHOLD = 8'd80, // 80°C threshold
  parameter HYSTERESIS = 8'd5
)(
  input clk, enable,
  input [7:0] temperature, // Temperature in °C
  output reg temp_alarm,
  output reg reset_out
);
  reg overtemp_condition = 1'b0;
  reg [1:0] alarm_counter = 2'b00;

  wire [7:0] temp_minus_hyst;
  assign temp_minus_hyst = TEMP_THRESHOLD - HYSTERESIS;

  // Move registers before combinational logic (retiming)
  reg next_overtemp_condition;
  reg [1:0] next_alarm_counter;
  reg next_temp_alarm;
  reg next_reset_out;

  always @* begin
    // Default assignments
    next_overtemp_condition = overtemp_condition;
    next_alarm_counter = alarm_counter;
    next_temp_alarm = temp_alarm;
    next_reset_out = reset_out;

    if (!enable) begin
      next_overtemp_condition = 1'b0;
      next_alarm_counter = 2'b00;
      next_temp_alarm = 1'b0;
      next_reset_out = 1'b0;
    end else begin
      if ((temperature > TEMP_THRESHOLD))
        next_overtemp_condition = 1'b1;
      else if ((temperature < temp_minus_hyst))
        next_overtemp_condition = 1'b0;

      next_temp_alarm = next_overtemp_condition;

      if (next_overtemp_condition)
        next_alarm_counter = (alarm_counter == 2'b11) ? 2'b11 : alarm_counter + 2'b01;
      else
        next_alarm_counter = 2'b00;

      next_reset_out = (next_alarm_counter == 2'b11);
    end
  end

  always @(posedge clk) begin
    overtemp_condition <= next_overtemp_condition;
    alarm_counter <= next_alarm_counter;
    temp_alarm <= next_temp_alarm;
    reset_out <= next_reset_out;
  end

endmodule