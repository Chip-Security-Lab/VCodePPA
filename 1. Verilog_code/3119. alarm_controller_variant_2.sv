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
    // State encoding
    localparam [1:0] DISARMED = 2'b00,
                     ARMED    = 2'b01,
                     TRIGGERED = 2'b10,
                     ALARM    = 2'b11;
                     
    reg [1:0] state, next_state;
    reg [7:0] trigger_counter;
    wire pin_match;
    wire grace_period_expired;
    
    // Pre-compute frequently used conditions
    assign pin_match = (pin == correct_pin);
    assign grace_period_expired = (trigger_counter >= 8'd30);
    
    // State register and outputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= DISARMED;
            trigger_counter <= 8'd0;
            alarm_sound <= 1'b0;
            status <= DISARMED;
        end else begin
            state <= next_state;
            
            // Counter logic - only increment in TRIGGERED state
            if (state == TRIGGERED) begin
                trigger_counter <= trigger_counter + 1'b1;
            end else if (next_state == DISARMED) begin
                // Reset counter when leaving alarm states
                trigger_counter <= 8'd0;
            end
            
            // Output assignments based on state
            alarm_sound <= (state == ALARM);
            status <= state;
        end
    end
    
    // Next state logic - optimized comparison chain
    always @(*) begin
        // Default assignment to prevent latches
        next_state = state;
        
        // First check highest priority condition - disarm with correct pin
        if (disarm && pin_match) begin
            next_state = DISARMED;
        end else begin
            // State-specific transitions
            case (state)
                DISARMED: begin
                    if (arm) next_state = ARMED;
                end
                ARMED: begin
                    if (sensor_triggered) next_state = TRIGGERED;
                end
                TRIGGERED: begin
                    if (grace_period_expired) next_state = ALARM;
                end
                ALARM: begin
                    // Already handled disarm condition above
                end
                default: next_state = DISARMED;
            endcase
        end
    end
endmodule