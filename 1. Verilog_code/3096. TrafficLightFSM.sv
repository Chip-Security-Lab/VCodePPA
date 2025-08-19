module TrafficLightFSM #(
    parameter GREEN_TIME = 30,
    parameter YELLOW_TIME = 5,
    parameter SENSOR_DELAY = 10
)(
    input clk, rst_n,
    input vehicle_sensor,
    output reg [2:0] lights // {red, yellow, green}
);
    // 使用localparam代替typedef enum
    localparam RED = 2'b00, GREEN = 2'b01, YELLOW = 2'b10;
    reg [1:0] current_state, next_state;
    
    reg [7:0] timer;
    reg sensor_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED;
            timer <= 0;
            sensor_reg <= 0;
            lights <= 3'b100; // 红灯亮
        end else begin
            current_state <= next_state;
            sensor_reg <= vehicle_sensor;
            
            if (current_state != next_state) begin
                timer <= 0;
            end else begin
                timer <= timer + 1;
            end

            case(current_state)
                RED: lights <= 3'b100;
                GREEN: begin
                    lights <= 3'b001;
                    // 检测到车辆时延长绿灯时间
                    if (sensor_reg && timer >= (GREEN_TIME - SENSOR_DELAY))
                        timer <= GREEN_TIME - SENSOR_DELAY;
                end
                YELLOW: lights <= 3'b010;
                default: lights <= 3'b100; // 默认红灯
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            RED: if (timer >= 15) next_state = GREEN;
            GREEN: if (timer >= GREEN_TIME) next_state = YELLOW;
            YELLOW: if (timer >= YELLOW_TIME) next_state = RED;
            default: next_state = RED;
        endcase
    end
endmodule