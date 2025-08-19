//SystemVerilog
module xor_behavioral(
    input a,                  // 时钟信号
    input b,                  // 复位信号
    input [7:0] multiplicand, // 8位被乘数
    input [7:0] multiplier,   // 8位乘数
    input start,              // 启动乘法运算信号
    output reg y,             // 完成信号
    output reg [15:0] product // 16位乘积结果
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALCULATE = 2'b01;
    localparam DONE = 2'b10;
    
    // 寄存器声明
    reg [1:0] state, next_state;
    reg [15:0] product_temp;
    reg [7:0] multiplier_temp;
    reg [8:0] multiplicand_temp; // 额外一位用于符号扩展
    reg [3:0] count;
    reg prev_bit;
    
    // 组合逻辑部分 - 前移寄存器计算
    reg [15:0] next_product_temp;
    reg [7:0] next_multiplier_temp;
    reg next_prev_bit;
    reg [3:0] next_count;
    reg [1:0] effective_next_state;
    
    // 组合逻辑计算
    always @(*) begin
        next_product_temp = product_temp;
        next_multiplier_temp = multiplier_temp;
        next_prev_bit = prev_bit;
        next_count = count;
        effective_next_state = next_state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_product_temp = 16'b0;
                    next_multiplier_temp = multiplier;
                    next_prev_bit = 1'b0;
                    next_count = 4'b0;
                end
            end
            
            CALCULATE: begin
                // Booth算法实现提前计算
                case ({multiplier_temp[0], prev_bit})
                    2'b01: next_product_temp = product_temp + {multiplicand_temp, 7'b0}; // +A
                    2'b10: next_product_temp = product_temp - {multiplicand_temp, 7'b0}; // -A
                    default: next_product_temp = product_temp; // 2'b00或2'b11，不做操作
                endcase
                
                // 更新状态
                next_prev_bit = multiplier_temp[0];
                next_multiplier_temp = {1'b0, multiplier_temp[7:1]}; // 右移一位
                next_count = count + 1'b1;
            end
        endcase
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: 
                next_state = start ? CALCULATE : IDLE;
            CALCULATE: 
                next_state = (count == 4'b1000) ? DONE : CALCULATE;
            DONE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // 时序逻辑 - 使用前向寄存器重定时
    always @(posedge a or posedge b) begin
        if (b) begin // 复位
            state <= IDLE;
            product <= 16'b0;
            y <= 1'b0;
            product_temp <= 16'b0;
            multiplier_temp <= 8'b0;
            multiplicand_temp <= 9'b0;
            count <= 4'b0;
            prev_bit <= 1'b0;
        end else begin
            state <= next_state;
            
            // 更新被乘数寄存器 - 移到输入后立即寄存
            if (state == IDLE && start)
                multiplicand_temp <= {multiplicand[7], multiplicand};
                
            // 应用前向重定时的寄存器更新
            product_temp <= next_product_temp;
            multiplier_temp <= next_multiplier_temp;
            prev_bit <= next_prev_bit;
            count <= next_count;
            
            // 处理输出
            if (next_state == DONE) begin
                product <= next_product_temp;
                y <= 1'b1;
            end else if (state == DONE && next_state == IDLE) begin
                y <= 1'b0;
            end
        end
    end
    
endmodule