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
    output reg [1:0] status
);

    parameter [1:0] DISARMED = 2'b00, ARMED = 2'b01,
                    TRIGGERED = 2'b10, ALARM = 2'b11;
    
    reg [1:0] state, next_state;
    reg [7:0] trigger_counter;
    
    // Multi-stage buffering for input signals
    reg disarm_stage1, disarm_stage2;
    reg [3:0] pin_stage1, pin_stage2;
    reg [3:0] correct_pin_stage1, correct_pin_stage2;
    reg sensor_triggered_stage1, sensor_triggered_stage2;
    reg arm_stage1, arm_stage2;
    
    // Multi-stage buffering for internal signals
    reg [1:0] state_stage1, state_stage2;
    reg [1:0] DISARMED_stage1, DISARMED_stage2, DISARMED_stage3;
    reg [1:0] next_state_stage1, next_state_stage2, next_state_stage3;
    reg [7:0] trigger_counter_stage1, trigger_counter_stage2;
    
    // Pin comparison pipeline stages
    reg pin_match_stage1, pin_match_stage2, pin_match_stage3;
    reg trigger_threshold_stage1, trigger_threshold_stage2;
    
    // Input stage pipelining
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Stage 1 input buffers
            disarm_stage1 <= 1'b0;
            pin_stage1 <= 4'b0;
            correct_pin_stage1 <= 4'b0;
            sensor_triggered_stage1 <= 1'b0;
            arm_stage1 <= 1'b0;
            
            // Stage 2 input buffers
            disarm_stage2 <= 1'b0;
            pin_stage2 <= 4'b0;
            correct_pin_stage2 <= 4'b0;
            sensor_triggered_stage2 <= 1'b0;
            arm_stage2 <= 1'b0;
        end else begin
            // Stage 1 buffering
            disarm_stage1 <= disarm;
            pin_stage1 <= pin;
            correct_pin_stage1 <= correct_pin;
            sensor_triggered_stage1 <= sensor_triggered;
            arm_stage1 <= arm;
            
            // Stage 2 buffering
            disarm_stage2 <= disarm_stage1;
            pin_stage2 <= pin_stage1;
            correct_pin_stage2 <= correct_pin_stage1;
            sensor_triggered_stage2 <= sensor_triggered_stage1;
            arm_stage2 <= arm_stage1;
        end
    end
    
    // Comparison pipeline stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pin_match_stage1 <= 1'b0;
            pin_match_stage2 <= 1'b0;
            pin_match_stage3 <= 1'b0;
            trigger_threshold_stage1 <= 1'b0;
            trigger_threshold_stage2 <= 1'b0;
        end else begin
            // Stage 1 - Initial comparison
            pin_match_stage1 <= (pin_stage1 == correct_pin_stage1);
            trigger_threshold_stage1 <= (trigger_counter >= 8'd30);
            
            // Stage 2 - Propagate results
            pin_match_stage2 <= pin_match_stage1;
            trigger_threshold_stage2 <= trigger_threshold_stage1;
            
            // Stage 3 - Final stage for pin match
            pin_match_stage3 <= pin_match_stage2;
        end
    end
    
    // State and constants buffering
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= DISARMED;
            state_stage2 <= DISARMED;
            DISARMED_stage1 <= DISARMED;
            DISARMED_stage2 <= DISARMED;
            DISARMED_stage3 <= DISARMED;
            trigger_counter_stage1 <= 8'd0;
            trigger_counter_stage2 <= 8'd0;
        end else begin
            state_stage1 <= state;
            state_stage2 <= state_stage1;
            DISARMED_stage1 <= DISARMED;
            DISARMED_stage2 <= DISARMED_stage1;
            DISARMED_stage3 <= DISARMED_stage2;
            trigger_counter_stage1 <= trigger_counter;
            trigger_counter_stage2 <= trigger_counter_stage1;
        end
    end
    
    // Next state logic with pipelined signals
    always @(*) begin
        case (state_stage2)
            DISARMED_stage3: begin
                next_state = arm_stage2 ? ARMED : DISARMED_stage3;
            end
            ARMED: begin
                if (disarm_stage2 && pin_match_stage3)
                    next_state = DISARMED_stage3;
                else if (sensor_triggered_stage2)
                    next_state = TRIGGERED;
                else
                    next_state = ARMED;
            end
            TRIGGERED: begin
                if (disarm_stage2 && pin_match_stage3)
                    next_state = DISARMED_stage3;
                else if (trigger_threshold_stage2)
                    next_state = ALARM;
                else
                    next_state = TRIGGERED;
            end
            ALARM: begin
                if (disarm_stage2 && pin_match_stage3)
                    next_state = DISARMED_stage3;
                else
                    next_state = ALARM;
            end
            default: next_state = DISARMED_stage3;
        endcase
    end
    
    // Next state buffer pipeline
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            next_state_stage1 <= DISARMED;
            next_state_stage2 <= DISARMED;
            next_state_stage3 <= DISARMED;
        end else begin
            next_state_stage1 <= next_state;
            next_state_stage2 <= next_state_stage1;
            next_state_stage3 <= next_state_stage2;
        end
    end
    
    // Main state machine with deeper pipeline
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= DISARMED;
            trigger_counter <= 8'd0;
            alarm_sound <= 1'b0;
            status <= 2'b00;
        end else begin
            state <= next_state_stage3;
            
            case (state)
                DISARMED_stage3: begin
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
endmodule