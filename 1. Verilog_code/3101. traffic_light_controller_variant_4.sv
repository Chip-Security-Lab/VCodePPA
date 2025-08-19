//SystemVerilog
// State machine module
module traffic_state_machine(
    input wire clk,
    input wire rst_n,
    output reg [1:0] state,
    output reg [1:0] next_state,
    output reg [4:0] counter
);
    parameter [1:0] HWY_GREEN = 2'b00, HWY_YELLOW = 2'b01,
                    FARM_GREEN = 2'b10, FARM_YELLOW = 2'b11;
    
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
endmodule

// Light control module
module traffic_light_control(
    input wire [1:0] state,
    output reg [1:0] highway_lights,
    output reg [1:0] farm_lights
);
    always @(*) begin
        case (state)
            2'b00: begin highway_lights = 2'b10; farm_lights = 2'b00; end
            2'b01: begin highway_lights = 2'b01; farm_lights = 2'b00; end
            2'b10: begin highway_lights = 2'b00; farm_lights = 2'b10; end
            2'b11: begin highway_lights = 2'b00; farm_lights = 2'b01; end
        endcase
    end
endmodule

// Top level module
module traffic_light_controller(
    input wire clk,
    input wire rst_n,
    output wire [1:0] highway_lights,
    output wire [1:0] farm_lights
);
    wire [1:0] state;
    wire [1:0] next_state;
    wire [4:0] counter;
    
    traffic_state_machine state_machine_inst(
        .clk(clk),
        .rst_n(rst_n),
        .state(state),
        .next_state(next_state),
        .counter(counter)
    );
    
    traffic_light_control light_control_inst(
        .state(state),
        .highway_lights(highway_lights),
        .farm_lights(farm_lights)
    );
endmodule