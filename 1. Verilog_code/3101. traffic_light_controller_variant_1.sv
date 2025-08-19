//SystemVerilog
module traffic_light_controller(
    input wire clk,
    input wire rst_n,
    output wire [1:0] highway_lights,
    output wire [1:0] farm_lights
);

    wire [3:0] state;

    // 实例化状态机模块
    state_machine state_machine_inst (
        .clk(clk),
        .rst_n(rst_n),
        .state(state)
    );

    // 实例化计数器模块
    counter counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .state(state),
        .counter(counter)
    );

    // 实例化输出控制模块
    output_control output_control_inst (
        .state(state),
        .highway_lights(highway_lights),
        .farm_lights(farm_lights)
    );

endmodule

module state_machine(
    input wire clk,
    input wire rst_n,
    output reg [3:0] state
);

    parameter [3:0] HWY_GREEN = 4'b1110,
                    HWY_YELLOW = 4'b1101,
                    FARM_GREEN = 4'b1011,
                    FARM_YELLOW = 4'b0111;
    reg [3:0] next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= HWY_GREEN;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            HWY_GREEN: next_state = HWY_YELLOW;
            HWY_YELLOW: next_state = FARM_GREEN;
            FARM_GREEN: next_state = FARM_YELLOW;
            FARM_YELLOW: next_state = HWY_GREEN;
            default: next_state = HWY_GREEN;
        endcase
    end

endmodule

module counter(
    input wire clk,
    input wire rst_n,
    input wire [3:0] state,
    output reg [4:0] counter
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 0;
        else if (counter >= 20)
            counter <= 0;
        else
            counter <= counter + 1;
    end

endmodule

module output_control(
    input wire [3:0] state,
    output reg [1:0] highway_lights,
    output reg [1:0] farm_lights
);

    parameter [3:0] HWY_GREEN = 4'b1110,
                    HWY_YELLOW = 4'b1101,
                    FARM_GREEN = 4'b1011,
                    FARM_YELLOW = 4'b0111;

    always @(*) begin
        case (state)
            HWY_GREEN: begin highway_lights = 2'b10; farm_lights = 2'b00; end
            HWY_YELLOW: begin highway_lights = 2'b01; farm_lights = 2'b00; end
            FARM_GREEN: begin highway_lights = 2'b00; farm_lights = 2'b10; end
            FARM_YELLOW: begin highway_lights = 2'b00; farm_lights = 2'b01; end
            default: begin highway_lights = 2'b00; farm_lights = 2'b00; end
        endcase
    end

endmodule