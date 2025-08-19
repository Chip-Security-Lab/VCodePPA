//SystemVerilog
module temp_controller(
    input wire clk, rst_n,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    output reg heat_on, cool_on, fan_on,
    output reg valid_out,
    input wire ready_in
);
    localparam IDLE=2'b00, HEATING=2'b01, COOLING=2'b10, FAN_ONLY=2'b11;
    reg [1:0] state, next;
    parameter HYSTERESIS = 8'd2;
    
    // Pre-calculate temperature boundaries for more efficient comparison
    wire [7:0] lower_bound = target_temp - HYSTERESIS;
    wire [7:0] upper_bound = target_temp + HYSTERESIS;
    
    // State transition logic
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= IDLE;
        else state <= next;
    
    // Optimized state machine with reduced comparison operations
    always @(*) begin
        // Default outputs
        heat_on = 1'b0;
        cool_on = 1'b0;
        fan_on = 1'b0;
        valid_out = 1'b0;
        
        // Default next state (avoid latches)
        next = state;
        
        case (state)
            IDLE: begin
                if (current_temp < lower_bound)
                    next = HEATING;
                else if (current_temp > upper_bound)
                    next = COOLING;
                else
                    next = IDLE;
            end
            
            HEATING: begin
                heat_on = 1'b1;
                fan_on = 1'b1;
                valid_out = 1'b1;
                if (current_temp >= target_temp && ready_in)
                    next = FAN_ONLY;
                else
                    next = HEATING;
            end
            
            COOLING: begin
                cool_on = 1'b1;
                fan_on = 1'b1;
                valid_out = 1'b1;
                if (current_temp <= target_temp && ready_in)
                    next = FAN_ONLY;
                else
                    next = COOLING;
            end
            
            FAN_ONLY: begin
                fan_on = 1'b1;
                valid_out = 1'b1;
                if (current_temp < lower_bound && ready_in)
                    next = HEATING;
                else if (current_temp > upper_bound && ready_in)
                    next = COOLING;
                else if (current_temp >= lower_bound && current_temp <= upper_bound && ready_in)
                    next = IDLE;
                else
                    next = FAN_ONLY;
            end
            
            default: next = IDLE;
        endcase
    end
endmodule