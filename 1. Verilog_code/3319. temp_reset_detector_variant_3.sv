//SystemVerilog
module temp_reset_detector #(
  parameter TEMP_THRESHOLD = 8'd80, // 80°C threshold
  parameter HYSTERESIS = 8'd5
)(
  input         clk,
  input         enable,
  input  [7:0]  temperature, // Temperature in °C
  output reg    temp_alarm,
  output reg    reset_out
);

  reg overtemp_state = 1'b0;
  reg [1:0] alarm_counter = 2'b00;

  localparam [7:0] LOWER_LIMIT = TEMP_THRESHOLD - HYSTERESIS;

  always @(posedge clk) begin
    if (!enable) begin
      overtemp_state  <= 1'b0;
      alarm_counter   <= 2'b00;
      temp_alarm      <= 1'b0;
      reset_out       <= 1'b0;
    end else begin
      // Optimized range-based comparison for hysteresis
      if (temperature > TEMP_THRESHOLD) begin
        overtemp_state <= 1'b1;
      end else if (temperature < LOWER_LIMIT) begin
        overtemp_state <= 1'b0;
      end

      temp_alarm <= overtemp_state;

      if (overtemp_state) begin
        if (alarm_counter != 2'b11)
          alarm_counter <= alarm_counter + 1'b1;
      end else begin
        alarm_counter <= 2'b00;
      end

      reset_out <= (alarm_counter == 2'b11);
    end
  end

endmodule