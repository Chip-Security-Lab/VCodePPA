//SystemVerilog
module TrafficLightFSM #(
    parameter GREEN_TIME = 30,
    parameter YELLOW_TIME = 5,
    parameter SENSOR_DELAY = 10
)(
    input clk, rst_n,
    input vehicle_sensor,
    output reg [2:0] lights_out // {red, yellow, green}
);
    // 状态定义
    localparam RED = 2'b00, GREEN = 2'b01, YELLOW = 2'b10;
    
    // 状态寄存器 - 流水线第1级
    reg [1:0] current_state_stage1, next_state_stage1;
    reg [1:0] current_state_stage2;
    reg [1:0] current_state_stage3;
    
    // 倒计时相关寄存器 - 分布在不同流水线级
    reg [7:0] count_down_stage1;        // 第1级流水线倒计时
    reg [7:0] count_down_stage2;        // 第2级流水线倒计时
    reg [7:0] count_down_stage3;        // 第3级流水线倒计时复制
    
    reg [7:0] threshold_stage1;         // 第1级流水线阈值
    reg [7:0] threshold_stage2;         // 第2级流水线阈值
    
    // 借位减法器的结果 - 流水线化
    wire [7:0] next_count_stage1;       // 第1级借位减法结果
    reg [7:0] next_count_stage2;        // 第2级借位减法结果
    
    wire borrow_stage1;                 // 第1级借位信号
    reg borrow_stage2;                  // 第2级借位信号
    
    // 传感器寄存器 - 流水线化
    reg sensor_reg_stage1;
    reg sensor_reg_stage2;
    reg sensor_reg_stage3;
    
    // 灯光控制 - 流水线最后级
    reg [2:0] lights_stage1;
    reg [2:0] lights_stage2;
    reg [2:0] lights_stage3;
    
    // 减法器和借位链 - 第1级计算
    wire [7:0] subtrahend = 8'h01;      // 每次减1
    wire [8:0] borrow_chain;            // 借位链
    assign borrow_chain[0] = 1'b0;      // 初始无借位
    
    // 借位减法器实现 - 第1级流水线
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: borrow_sub
            assign next_count_stage1[i] = count_down_stage1[i] ^ subtrahend[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = (~count_down_stage1[i] & subtrahend[i]) | 
                                      (~count_down_stage1[i] & borrow_chain[i]) | 
                                      (subtrahend[i] & borrow_chain[i]);
        end
    endgenerate
    
    assign borrow_stage1 = borrow_chain[8];  // 最终借位
    
    // 状态阈值设置 - 第1级流水线逻辑
    always @(*) begin
        case(current_state_stage1)
            RED:     threshold_stage1 = 8'd15;
            GREEN:   threshold_stage1 = GREEN_TIME;
            YELLOW:  threshold_stage1 = YELLOW_TIME;
            default: threshold_stage1 = 8'd15;
        endcase
    end

    // 状态转换逻辑 - 第1级流水线
    always @(*) begin
        next_state_stage1 = current_state_stage1;
        case(current_state_stage1)
            RED:     if (count_down_stage1 == 8'd0) next_state_stage1 = GREEN;
            GREEN:   if (count_down_stage1 == 8'd0) next_state_stage1 = YELLOW;
            YELLOW:  if (count_down_stage1 == 8'd0) next_state_stage1 = RED;
            default: next_state_stage1 = RED;
        endcase
    end
    
    // 流水线第1级 - 状态更新和计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage1 <= RED;
            count_down_stage1 <= 8'd15;
            sensor_reg_stage1 <= 0;
            lights_stage1 <= 3'b100;
            
            // 初始化第2级和第3级流水线
            current_state_stage2 <= RED;
            count_down_stage2 <= 8'd15;
            threshold_stage2 <= 8'd15;
            sensor_reg_stage2 <= 0;
            next_count_stage2 <= 8'd14;
            borrow_stage2 <= 0;
            lights_stage2 <= 3'b100;
            
            current_state_stage3 <= RED;
            count_down_stage3 <= 8'd15;
            sensor_reg_stage3 <= 0;
            lights_stage3 <= 3'b100;
            lights_out <= 3'b100;
        end else begin
            // 第1级向第2级传递数据
            current_state_stage2 <= current_state_stage1;
            count_down_stage2 <= count_down_stage1;
            threshold_stage2 <= threshold_stage1;
            sensor_reg_stage2 <= vehicle_sensor;
            next_count_stage2 <= next_count_stage1;
            borrow_stage2 <= borrow_stage1;
            
            // 第1级计算基本灯光状态
            case(current_state_stage1)
                RED:     lights_stage1 <= 3'b100;
                GREEN:   lights_stage1 <= 3'b001;
                YELLOW:  lights_stage1 <= 3'b010;
                default: lights_stage1 <= 3'b100;
            endcase
        end
    end
    
    // 流水线第2级 - 计数器和状态更新的处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位由第1级处理
        end else begin
            // 第2级向第3级传递数据
            current_state_stage3 <= current_state_stage2;
            sensor_reg_stage3 <= sensor_reg_stage2;
            lights_stage3 <= lights_stage2;
            
            // 状态逻辑和计数器更新处理
            if (current_state_stage2 != next_state_stage1 && next_state_stage1 != current_state_stage1) begin
                // 状态转换时重置倒计时器 - 处理非连续性状态变化
                case(next_state_stage1)
                    RED:     count_down_stage3 <= 8'd15;
                    GREEN:   count_down_stage3 <= GREEN_TIME;
                    YELLOW:  count_down_stage3 <= YELLOW_TIME;
                    default: count_down_stage3 <= 8'd15;
                endcase
            end else if (count_down_stage2 != 8'd0) begin
                count_down_stage3 <= next_count_stage2;  // 正常倒计时
            end else begin
                count_down_stage3 <= count_down_stage2;  // 保持0值
            end
            
            // 灯光控制细节处理
            lights_stage2 <= lights_stage1;
            if (current_state_stage2 == GREEN && sensor_reg_stage2 && count_down_stage2 <= SENSOR_DELAY) begin
                count_down_stage3 <= SENSOR_DELAY;  // 检测到车辆时延长绿灯时间
            end
        end
    end
    
    // 流水线第3级 - 最终输出处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位由第1级处理
        end else begin
            // 第3级最终处理，确保状态变化时灯光立即更新
            lights_out <= lights_stage3;
            
            // 状态更新最终处理
            current_state_stage1 <= (current_state_stage3 != next_state_stage1) ? 
                                    next_state_stage1 : current_state_stage3;
            
            // 计数器最终更新
            count_down_stage1 <= count_down_stage3;
        end
    end
endmodule