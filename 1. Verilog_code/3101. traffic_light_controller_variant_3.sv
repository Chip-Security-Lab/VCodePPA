//SystemVerilog
module traffic_light_controller(
    input wire clk,
    input wire rst_n,
    output reg [1:0] highway_lights,
    output reg [1:0] farm_lights
);
    parameter [1:0] HWY_GREEN = 2'b00, HWY_YELLOW = 2'b01, 
                    FARM_GREEN = 2'b10, FARM_YELLOW = 2'b11;
    parameter COUNTER_MAX = 5'd20;
    
    reg [1:0] state, next_state;
    reg [4:0] counter;
    wire counter_done;
    wire [1:0] state_encoded;
    
    // Pre-compute counter done signal
    assign counter_done = (counter >= COUNTER_MAX);
    
    // Encode state transitions
    assign state_encoded = (state == HWY_GREEN) ? HWY_YELLOW :
                          (state == HWY_YELLOW) ? FARM_GREEN :
                          (state == FARM_GREEN) ? FARM_YELLOW : HWY_GREEN;
    
    // State and counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= HWY_GREEN;
            counter <= 5'd0;
        end else begin
            state <= counter_done ? state_encoded : state;
            counter <= counter_done ? 5'd0 : counter + 1'b1;
        end
    end
    
    // Output logic with balanced paths
    always @(*) begin
        highway_lights = (state == HWY_GREEN) ? 2'b10 :
                        (state == HWY_YELLOW) ? 2'b01 : 2'b00;
                        
        farm_lights = (state == FARM_GREEN) ? 2'b10 :
                     (state == FARM_YELLOW) ? 2'b01 : 2'b00;
    end
endmodule