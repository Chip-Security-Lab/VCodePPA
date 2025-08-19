//SystemVerilog
module traffic_light_controller(
    input wire clk,
    input wire rst_n,
    output reg [1:0] highway_lights,
    output reg [1:0] farm_lights
);
    parameter [1:0] HWY_GREEN = 2'b00, HWY_YELLOW = 2'b01, 
                    FARM_GREEN = 2'b10, FARM_YELLOW = 2'b11;
    parameter TIMER_MAX = 5'd20;
    
    reg [1:0] state, next_state;
    reg [4:0] counter;
    wire timer_expired;
    
    // Karatsuba multiplier implementation for 5-bit counter
    wire [4:0] counter_plus_1;
    wire [4:0] counter_plus_1_low = counter[1:0] + 1'b1;
    wire [4:0] counter_plus_1_high = counter[4:2] + (counter_plus_1_low[2] ? 1'b1 : 1'b0);
    assign counter_plus_1 = {counter_plus_1_high[2:0], counter_plus_1_low[1:0]};
    
    assign timer_expired = (counter >= TIMER_MAX);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= HWY_GREEN;
            counter <= 5'd0;
        end else begin
            state <= timer_expired ? next_state : state;
            counter <= timer_expired ? 5'd0 : counter_plus_1;
        end
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            HWY_GREEN:   next_state = HWY_YELLOW;
            HWY_YELLOW:  next_state = FARM_GREEN;
            FARM_GREEN:  next_state = FARM_YELLOW;
            FARM_YELLOW: next_state = HWY_GREEN;
        endcase
    end
    
    always @(*) begin
        highway_lights = 2'b00;
        farm_lights = 2'b00;
        case (state)
            HWY_GREEN:   highway_lights = 2'b10;
            HWY_YELLOW:  highway_lights = 2'b01;
            FARM_GREEN:  farm_lights = 2'b10;
            FARM_YELLOW: farm_lights = 2'b01;
        endcase
    end
endmodule