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

  // Stage 1: Calculate hysteresis low and compare temperature
  reg  [7:0]   hysteresis_low_stage1;
  reg          temp_above_threshold_stage1;
  reg          temp_below_hysteresis_stage1;
  reg  [7:0]   temperature_stage1;
  reg          enable_stage1;

  // Stage 2: Priority logic for overtemp condition
  reg          overtemp_condition_stage2;
  reg          overtemp_condition_stage2_d; // delayed for alarm assignment
  reg          enable_stage2;

  // Stage 3: Alarm counter and temp_alarm
  reg  [1:0]   alarm_counter_stage3;
  reg          temp_alarm_stage3;
  reg          overtemp_condition_stage3;
  reg          enable_stage3;

  // Stage 4: Reset output generation
  reg          reset_out_stage4;
  reg  [1:0]   alarm_counter_stage4;
  reg          enable_stage4;

  // Stage 1: Calculate comparator values
  always @(posedge clk) begin
    if (!enable) begin
      hysteresis_low_stage1         <= 8'd0;
      temp_above_threshold_stage1   <= 1'b0;
      temp_below_hysteresis_stage1  <= 1'b0;
      temperature_stage1            <= 8'd0;
      enable_stage1                 <= 1'b0;
    end else begin
      hysteresis_low_stage1         <= TEMP_THRESHOLD - HYSTERESIS;
      temp_above_threshold_stage1   <= (temperature > TEMP_THRESHOLD);
      temp_below_hysteresis_stage1  <= (temperature < (TEMP_THRESHOLD - HYSTERESIS));
      temperature_stage1            <= temperature;
      enable_stage1                 <= enable;
    end
  end

  // Stage 2: Priority logic for overtemp detection
  always @(posedge clk) begin
    if (!enable_stage1) begin
      overtemp_condition_stage2     <= 1'b0;
      overtemp_condition_stage2_d   <= 1'b0;
      enable_stage2                 <= 1'b0;
    end else begin
      case ({temp_above_threshold_stage1, temp_below_hysteresis_stage1})
        2'b10: overtemp_condition_stage2 <= 1'b1;
        2'b01: overtemp_condition_stage2 <= 1'b0;
        default: overtemp_condition_stage2 <= overtemp_condition_stage2;
      endcase
      overtemp_condition_stage2_d   <= overtemp_condition_stage2;
      enable_stage2                 <= enable_stage1;
    end
  end

  // Stage 3: Alarm counter and temp_alarm
  always @(posedge clk) begin
    if (!enable_stage2) begin
      alarm_counter_stage3          <= 2'b00;
      temp_alarm_stage3             <= 1'b0;
      overtemp_condition_stage3     <= 1'b0;
      enable_stage3                 <= 1'b0;
    end else begin
      overtemp_condition_stage3     <= overtemp_condition_stage2_d;
      temp_alarm_stage3             <= overtemp_condition_stage2_d;
      if (overtemp_condition_stage2_d) begin
        if (alarm_counter_stage3 != 2'b11)
          alarm_counter_stage3      <= alarm_counter_stage3 + 1'b1;
        else
          alarm_counter_stage3      <= alarm_counter_stage3;
      end else begin
        alarm_counter_stage3        <= 2'b00;
      end
      enable_stage3                 <= enable_stage2;
    end
  end

  // Stage 4: Output logic for reset_out
  always @(posedge clk) begin
    if (!enable_stage3) begin
      reset_out_stage4              <= 1'b0;
      alarm_counter_stage4          <= 2'b00;
      enable_stage4                 <= 1'b0;
    end else begin
      alarm_counter_stage4          <= alarm_counter_stage3;
      reset_out_stage4              <= (alarm_counter_stage3 == 2'b11);
      enable_stage4                 <= enable_stage3;
    end
  end

  // Output assignments
  always @(posedge clk) begin
    if (!enable_stage4) begin
      temp_alarm                   <= 1'b0;
      reset_out                    <= 1'b0;
    end else begin
      temp_alarm                   <= temp_alarm_stage3;
      reset_out                    <= reset_out_stage4;
    end
  end

endmodule