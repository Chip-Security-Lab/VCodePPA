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
    
    // Optimized comparison logic using single comparator
    wire [8:0] temp_diff = {1'b0, current_temp} - {1'b0, target_temp};
    wire temp_in_range = (temp_diff[8:1] <= HYSTERESIS);
    wire temp_above_target = temp_diff[8];
    wire temp_below_target = ~temp_diff[8] && (temp_diff[7:0] != 0);
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= IDLE;
        else state <= next;
    
    always @(*) begin
        heat_on = 1'b0;
        cool_on = 1'b0;
        fan_on = 1'b0;
        
        case (state)
            IDLE: begin
                if (temp_below_target && !temp_in_range)
                    next = HEATING;
                else if (temp_above_target && !temp_in_range)
                    next = COOLING;
                else
                    next = IDLE;
            end
            HEATING: begin
                heat_on = 1'b1;
                fan_on = 1'b1;
                next = temp_above_target ? FAN_ONLY : HEATING;
            end
            COOLING: begin
                cool_on = 1'b1;
                fan_on = 1'b1;
                next = temp_below_target ? FAN_ONLY : COOLING;
            end
            FAN_ONLY: begin
                fan_on = 1'b1;
                if (temp_below_target && !temp_in_range)
                    next = HEATING;
                else if (temp_above_target && !temp_in_range)
                    next = COOLING;
                else if (temp_in_range)
                    next = IDLE;
                else
                    next = FAN_ONLY;
            end
        endcase
    end
endmodule