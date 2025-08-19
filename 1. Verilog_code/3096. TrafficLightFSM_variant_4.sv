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
    // 使用清晰的状态编码和参数定义
    localparam RED = 2'b00, GREEN = 2'b01, YELLOW = 2'b10;

    // 状态寄存器和管线化结构
    reg [1:0] current_state, next_state;
    reg [1:0] state_pipe;  // 增加状态流水线寄存器
    
    // 计时器和传感器相关寄存器
    reg [7:0] timer;
    reg [7:0] timer_next;
    reg sensor_reg, sensor_pipe;  // 增加传感器流水线寄存器
    reg timer_reset;
    
    // 分离传感器采样逻辑，形成输入流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sensor_reg <= 0;
            sensor_pipe <= 0;
        end else begin
            sensor_reg <= vehicle_sensor;  // 第一级采样
            sensor_pipe <= sensor_reg;     // 第二级滤波
        end
    end
    
    // 状态转换逻辑 - 分离为独立模块以减少关键路径
    always @(*) begin
        next_state = current_state;
        timer_reset = 1'b0;
        
        case(current_state)
            RED:    if (timer >= 15) begin
                        next_state = GREEN;
                        timer_reset = 1'b1;
                    end
            GREEN:  if (timer >= GREEN_TIME) begin
                        next_state = YELLOW;
                        timer_reset = 1'b1;
                    end
            YELLOW: if (timer >= YELLOW_TIME) begin
                        next_state = RED;
                        timer_reset = 1'b1;
                    end
            default: next_state = RED;
        endcase
    end
    
    // 计时器逻辑 - 分离为独立计算单元
    always @(*) begin
        timer_next = timer;
        
        if (timer_reset) begin
            timer_next = 8'd0;
        end else begin
            // 绿灯时的传感器延长特殊处理
            if (current_state == GREEN && sensor_pipe && 
                (timer >= (GREEN_TIME - SENSOR_DELAY))) begin
                timer_next = GREEN_TIME - SENSOR_DELAY;
            end else begin
                timer_next = timer + 8'd1;
            end
        end
    end
    
    // 状态和计时器更新 - 寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED;
            state_pipe <= RED;
            timer <= 8'd0;
        end else begin
            current_state <= next_state;
            state_pipe <= current_state;  // 流水线化状态用于输出
            timer <= timer_next;
        end
    end
    
    // 输出逻辑 - 分离为独立的输出流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lights <= 3'b100; // 红灯亮
        end else begin
            case(state_pipe)  // 使用流水线化状态产生输出
                RED:    lights <= 3'b100;
                GREEN:  lights <= 3'b001;
                YELLOW: lights <= 3'b010;
                default: lights <= 3'b100; // 默认红灯
            endcase
        end
    end
endmodule