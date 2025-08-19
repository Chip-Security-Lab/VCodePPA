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
  
  always @(posedge clk) begin
    if (!enable) begin
      overtemp_condition <= 1'b0;
      alarm_counter <= 2'b00;
      temp_alarm <= 1'b0;
      reset_out <= 1'b0;
    end else begin
      if (temperature > TEMP_THRESHOLD)
        overtemp_condition <= 1'b1;
      else if (temperature < (TEMP_THRESHOLD - HYSTERESIS))
        overtemp_condition <= 1'b0;
        
      temp_alarm <= overtemp_condition;
      
      if (overtemp_condition)
        alarm_counter <= (alarm_counter == 2'b11) ? 2'b11 : alarm_counter + 1;
      else
        alarm_counter <= 2'b00;
        
      reset_out <= (alarm_counter == 2'b11);
    end
  end
endmodule