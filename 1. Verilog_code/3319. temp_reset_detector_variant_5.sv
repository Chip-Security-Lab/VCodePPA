//SystemVerilog
// SystemVerilog
// Top-level module: Hierarchically structured temperature reset detector (optimized)
module temp_reset_detector #(
    parameter TEMP_THRESHOLD = 8'd80, // 80°C threshold
    parameter HYSTERESIS = 8'd5
)(
    input  wire         clk,
    input  wire         enable,
    input  wire [7:0]   temperature, // Temperature in °C
    output wire         temp_alarm,
    output wire         reset_out
);

    // Internal signals for submodule interconnection
    wire                overtemp_condition;
    wire [1:0]          alarm_counter;

    // Overtemperature detection with hysteresis
    overtemp_hysteresis #(
        .TEMP_THRESHOLD(TEMP_THRESHOLD),
        .HYSTERESIS(HYSTERESIS)
    ) u_overtemp_hysteresis (
        .clk(clk),
        .enable(enable),
        .temperature(temperature),
        .overtemp_condition(overtemp_condition)
    );

    // Alarm and counter logic
    alarm_counter_logic u_alarm_counter_logic (
        .clk(clk),
        .enable(enable),
        .overtemp_condition(overtemp_condition),
        .alarm_counter(alarm_counter),
        .temp_alarm(temp_alarm)
    );

    // Reset logic based on alarm counter
    reset_output_logic u_reset_output_logic (
        .clk(clk),
        .enable(enable),
        .alarm_counter(alarm_counter),
        .reset_out(reset_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: Overtemperature detection with hysteresis (optimized)
// Detects overtemperature condition with hysteresis to prevent rapid toggling
// -----------------------------------------------------------------------------
module overtemp_hysteresis #(
    parameter TEMP_THRESHOLD = 8'd80,
    parameter HYSTERESIS = 8'd5
)(
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  temperature,
    output reg         overtemp_condition
);
    // Pre-calculate hysteresis threshold for efficient comparison
    wire [7:0] hysteresis_threshold = TEMP_THRESHOLD - HYSTERESIS;

    always @(posedge clk) begin
        if (!enable) begin
            overtemp_condition <= 1'b0;
        end
        else if (!overtemp_condition && temperature > TEMP_THRESHOLD) begin
            overtemp_condition <= 1'b1;
        end
        else if (overtemp_condition && temperature < hysteresis_threshold) begin
            overtemp_condition <= 1'b0;
        end
        // else retain previous state
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Alarm counter logic (optimized)
// Counts consecutive overtemperature detections and asserts alarm
// -----------------------------------------------------------------------------
module alarm_counter_logic (
    input  wire        clk,
    input  wire        enable,
    input  wire        overtemp_condition,
    output reg  [1:0]  alarm_counter,
    output reg         temp_alarm
);
    // Efficient counter update and alarm logic
    always @(posedge clk) begin
        if (!enable) begin
            alarm_counter <= 2'b00;
            temp_alarm    <= 1'b0;
        end
        else begin
            if (overtemp_condition) begin
                alarm_counter <= (alarm_counter == 2'b11) ? 2'b11 : alarm_counter + 2'b01;
                temp_alarm    <= 1'b1;
            end
            else begin
                alarm_counter <= 2'b00;
                temp_alarm    <= 1'b0;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Reset output logic (optimized)
// Asserts reset_out when alarm_counter reaches maximum count
// -----------------------------------------------------------------------------
module reset_output_logic (
    input  wire       clk,
    input  wire       enable,
    input  wire [1:0] alarm_counter,
    output reg        reset_out
);
    always @(posedge clk) begin
        if (!enable) begin
            reset_out <= 1'b0;
        end
        else begin
            reset_out <= &alarm_counter; // Equivalent to alarm_counter == 2'b11
        end
    end
endmodule