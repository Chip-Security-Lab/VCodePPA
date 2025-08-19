//SystemVerilog
module temp_controller(
    input wire clk, rst_n,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    output reg heat_on, cool_on, fan_on
);
    localparam IDLE=2'b00, HEATING=2'b01, COOLING=2'b10, FAN_ONLY=2'b11;
    reg [1:0] state, next;
    parameter HYSTERESIS = 8'd2;
    
    wire [7:0] temp_upper_bound = target_temp + HYSTERESIS;
    wire [7:0] temp_lower_bound = target_temp - HYSTERESIS;
    wire temp_above_upper = current_temp > temp_upper_bound;
    wire temp_below_lower = current_temp < temp_lower_bound;
    wire temp_in_range = ~temp_above_upper & ~temp_below_lower;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= IDLE;
        else state <= next;
    
    always @(*) begin
        heat_on = 1'b0;
        cool_on = 1'b0;
        fan_on = 1'b0;
        
        case (state)
            IDLE: begin
                next = temp_below_lower ? HEATING :
                       temp_above_upper ? COOLING : IDLE;
            end
            HEATING: begin
                heat_on = 1'b1;
                fan_on = 1'b1;
                next = ~temp_below_lower ? FAN_ONLY : HEATING;
            end
            COOLING: begin
                cool_on = 1'b1;
                fan_on = 1'b1;
                next = ~temp_above_upper ? FAN_ONLY : COOLING;
            end
            FAN_ONLY: begin
                fan_on = 1'b1;
                next = temp_below_lower ? HEATING :
                       temp_above_upper ? COOLING :
                       (temp_in_range) ? IDLE : FAN_ONLY;
            end
        endcase
    end
endmodule