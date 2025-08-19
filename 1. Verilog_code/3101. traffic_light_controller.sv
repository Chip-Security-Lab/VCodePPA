module traffic_light_controller(
    input wire clk,
    input wire rst_n,
    output reg [1:0] highway_lights, // 00:R, 01:Y, 10:G
    output reg [1:0] farm_lights     // 00:R, 01:Y, 10:G
);
    parameter [1:0] HWY_GREEN = 2'b00, HWY_YELLOW = 2'b01, 
                    FARM_GREEN = 2'b10, FARM_YELLOW = 2'b11;
    reg [1:0] state, next_state;
    reg [4:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= HWY_GREEN;
            counter <= 0;
        end else begin
            if (counter >= 20) begin
                state <= next_state;
                counter <= 0;
            end else
                counter <= counter + 1;
        end
    end
    
    always @(*) begin
        case (state)
            HWY_GREEN: next_state = HWY_YELLOW;
            HWY_YELLOW: next_state = FARM_GREEN;
            FARM_GREEN: next_state = FARM_YELLOW;
            FARM_YELLOW: next_state = HWY_GREEN;
        endcase
    end
    
    always @(*) begin
        case (state)
            HWY_GREEN: begin highway_lights = 2'b10; farm_lights = 2'b00; end
            HWY_YELLOW: begin highway_lights = 2'b01; farm_lights = 2'b00; end
            FARM_GREEN: begin highway_lights = 2'b00; farm_lights = 2'b10; end
            FARM_YELLOW: begin highway_lights = 2'b00; farm_lights = 2'b01; end
        endcase
    end
endmodule