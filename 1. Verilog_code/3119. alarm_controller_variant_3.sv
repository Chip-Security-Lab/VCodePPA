//SystemVerilog
module alarm_controller(
    input wire clk,
    input wire reset,
    input wire arm,
    input wire disarm,
    input wire [3:0] pin,
    input wire [3:0] correct_pin,
    input wire sensor_triggered,
    output reg alarm_sound,
    output reg [1:0] status // 00:disarmed, 01:armed, 10:triggered, 11:sounding
);
    parameter [1:0] DISARMED = 2'b00, ARMED = 2'b01,
                    TRIGGERED = 2'b10, ALARM = 2'b11;
    reg [1:0] state, next_state;
    reg [7:0] trigger_counter;

    // Shift-and-Add Multiplier for 8-bit multiplication
    function [15:0] shift_add_multiplier;
        input [7:0] multiplicand;
        input [7:0] multiplier;
        reg [15:0] product;
        reg [7:0] temp_multiplier;
        reg [7:0] temp_multiplicand;
        integer i;
        begin
            product = 16'b0;
            temp_multiplier = multiplier;
            temp_multiplicand = multiplicand;

            for (i = 0; i < 8; i = i + 1) begin
                if (temp_multiplier[0]) begin
                    product = product + temp_multiplicand;
                end
                temp_multiplicand = temp_multiplicand << 1; // Shift multiplicand left
                temp_multiplier = temp_multiplier >> 1;     // Shift multiplier right
            end
            shift_add_multiplier = product;
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= DISARMED;
            trigger_counter <= 8'd0;
            alarm_sound <= 1'b0;
            status <= 2'b00;
        end else begin
            state <= next_state;

            case (state)
                DISARMED: begin
                    alarm_sound <= 1'b0;
                    status <= 2'b00;
                end
                ARMED: begin
                    alarm_sound <= 1'b0;
                    status <= 2'b01;
                end
                TRIGGERED: begin
                    trigger_counter <= trigger_counter + 1'b1;
                    alarm_sound <= 1'b0;
                    status <= 2'b10;
                end
                ALARM: begin
                    alarm_sound <= 1'b1;
                    status <= 2'b11;
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            DISARMED: begin
                next_state = arm ? ARMED : DISARMED;
            end
            ARMED: begin
                if (disarm && (pin == correct_pin))
                    next_state = DISARMED;
                else if (sensor_triggered)
                    next_state = TRIGGERED;
                else
                    next_state = ARMED;
            end
            TRIGGERED: begin
                if (disarm && (pin == correct_pin))
                    next_state = DISARMED;
                else if (trigger_counter >= 8'd30) // Grace period
                    next_state = ALARM;
                else
                    next_state = TRIGGERED;
            end
            ALARM: begin
                if (disarm && (pin == correct_pin))
                    next_state = DISARMED;
                else
                    next_state = ALARM;
            end
            default: next_state = DISARMED;
        endcase
    end
endmodule