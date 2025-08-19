//SystemVerilog
module TrafficLightFSM #(
    parameter GREEN_TIME = 30,
    parameter YELLOW_TIME = 5,
    parameter SENSOR_DELAY = 10
)(
    input clk, rst_n,
    input vehicle_sensor,
    output reg [2:0] lights // {red, yellow, green}
);
    // 状态编码优化为独热码，减少状态转换逻辑电路
    localparam [2:0] RED = 3'b001, GREEN = 3'b010, YELLOW = 3'b100;
    reg [2:0] current_state, next_state;
    
    // 计时器和传感器寄存器
    reg [6:0] timer;  // 减小位宽以节省资源
    reg sensor_reg, sensor_valid;
    
    // 预计算状态转换条件
    wire red_to_green = (current_state == RED) && (timer >= 15);
    wire green_to_yellow = (current_state == GREEN) && (timer >= GREEN_TIME);
    wire yellow_to_red = (current_state == YELLOW) && (timer >= YELLOW_TIME);
    wire extend_green = sensor_valid && (timer >= (GREEN_TIME - SENSOR_DELAY));

    // 当前状态和计时器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED;
            timer <= 0;
            sensor_reg <= 0;
            sensor_valid <= 0;
            lights <= 3'b100; // 红灯亮
        end else begin
            // 传感器边缘检测优化
            sensor_reg <= vehicle_sensor;
            sensor_valid <= vehicle_sensor & ~sensor_reg;
            
            // 状态转换
            current_state <= next_state;
            
            // 计时器逻辑优化
            if (current_state != next_state || (extend_green && current_state == GREEN)) begin
                timer <= 0;
            end else if (timer != 7'h7F) begin
                timer <= timer + 1'b1;
            end

            // 输出逻辑优化
            case(current_state)
                RED:    lights <= 3'b100;
                GREEN:  lights <= 3'b001;
                YELLOW: lights <= 3'b010;
                default: lights <= 3'b100;
            endcase
        end
    end

    // 状态转换逻辑优化
    always @(*) begin
        case(current_state)
            RED:    next_state = red_to_green ? GREEN : RED;
            GREEN:  next_state = green_to_yellow ? YELLOW : GREEN;
            YELLOW: next_state = yellow_to_red ? RED : YELLOW;
            default: next_state = RED;
        endcase
    end
endmodule