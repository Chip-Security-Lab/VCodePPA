module temp_controller(
    input wire clk, rst_n,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    output reg heat_on, cool_on, fan_on
);
    localparam IDLE=2'b00, HEATING=2'b01, COOLING=2'b10, FAN_ONLY=2'b11;
    reg [1:0] state, next;
    parameter HYSTERESIS = 8'd2;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= IDLE;
        else state <= next;
    
    always @(*) begin
        heat_on = 1'b0;
        cool_on = 1'b0;
        fan_on = 1'b0;
        
        case (state)
            IDLE: begin
                if (current_temp < target_temp - HYSTERESIS)
                    next = HEATING;
                else if (current_temp > target_temp + HYSTERESIS)
                    next = COOLING;
                else
                    next = IDLE;
            end
            HEATING: begin
                heat_on = 1'b1;
                fan_on = 1'b1;
                if (current_temp >= target_temp)
                    next = FAN_ONLY;
                else
                    next = HEATING;
            end
            COOLING: begin
                cool_on = 1'b1;
                fan_on = 1'b1;
                if (current_temp <= target_temp)
                    next = FAN_ONLY;
                else
                    next = COOLING;
            end
            FAN_ONLY: begin
                fan_on = 1'b1;
                if (current_temp < target_temp - HYSTERESIS)
                    next = HEATING;
                else if (current_temp > target_temp + HYSTERESIS)
                    next = COOLING;
                else if ((state == FAN_ONLY) && 
                        (current_temp >= target_temp - HYSTERESIS) && 
                        (current_temp <= target_temp + HYSTERESIS))
                    next = IDLE;
                else
                    next = FAN_ONLY;
            end
        endcase
    end
endmodule