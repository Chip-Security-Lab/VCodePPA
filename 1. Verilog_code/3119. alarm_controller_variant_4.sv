//SystemVerilog
module alarm_controller(
    input wire clk,
    input wire reset,
    input wire arm_req,
    output reg arm_ack,
    input wire disarm_req,
    output reg disarm_ack,
    input wire [3:0] pin,
    input wire [3:0] correct_pin,
    input wire sensor_req,
    output reg sensor_ack,
    output reg alarm_sound,
    output reg [1:0] status // 00:disarmed, 01:armed, 10:triggered, 11:sounding
);
    parameter [1:0] DISARMED = 2'b00, ARMED = 2'b01,
                    TRIGGERED = 2'b10, ALARM = 2'b11;
    reg [1:0] state, next_state;
    reg [7:0] trigger_counter;

    // Internal signals for Req-Ack protocol handling
    reg arm_processed;
    reg disarm_processed;
    reg sensor_processed;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= DISARMED;
            trigger_counter <= 8'd0;
            alarm_sound <= 1'b0;
            status <= 2'b00;
            arm_ack <= 1'b0;
            disarm_ack <= 1'b0;
            sensor_ack <= 1'b0;
            arm_processed <= 1'b0;
            disarm_processed <= 1'b0;
            sensor_processed <= 1'b0;
        end else begin
            state <= next_state;

            // Reset processed flags when request is deasserted
            if (!arm_req) begin
                arm_processed <= 1'b0;
                arm_ack <= 1'b0;
            end

            if (!disarm_req) begin
                disarm_processed <= 1'b0;
                disarm_ack <= 1'b0;
            end

            if (!sensor_req) begin
                sensor_processed <= 1'b0;
                sensor_ack <= 1'b0;
            end

            // Generate acknowledgment signals
            if (arm_req && !arm_processed) begin
                arm_ack <= 1'b1;
                arm_processed <= 1'b1;
            end

            if (disarm_req && !disarm_processed) begin
                disarm_ack <= 1'b1;
                disarm_processed <= 1'b1;
            end

            if (sensor_req && !sensor_processed) begin
                sensor_ack <= 1'b1;
                sensor_processed <= 1'b1;
            end

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
                next_state = (arm_req && !arm_processed) ? ARMED : DISARMED;
            end
            ARMED: begin
                if (disarm_req && !disarm_processed && (pin == correct_pin))
                    next_state = DISARMED;
                else if (sensor_req && !sensor_processed)
                    next_state = TRIGGERED;
                else
                    next_state = ARMED;
            end
            TRIGGERED: begin
                if (disarm_req && !disarm_processed && (pin == correct_pin))
                    next_state = DISARMED;
                else if (trigger_counter >= 8'd30) // Grace period
                    next_state = ALARM;
                else
                    next_state = TRIGGERED;
            end
            ALARM: begin
                if (disarm_req && !disarm_processed && (pin == correct_pin))
                    next_state = DISARMED;
                else
                    next_state = ALARM;
            end
            default: next_state = DISARMED;
        endcase
    end
endmodule