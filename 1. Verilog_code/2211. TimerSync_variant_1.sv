//SystemVerilog
module TimerSync #(
    parameter WIDTH = 16
)(
    input  wire         clk,       // 系统时钟
    input  wire         rst_n,     // 低电平有效复位
    input  wire         enable,    // 计时器使能信号
    output reg          timer_out  // 计时器输出脉冲
);
    // 计数器分段实现，提高时序性能
    reg [WIDTH/2-1:0] counter_low;   // 低位计数器
    reg [WIDTH/2-1:0] counter_high;  // 高位计数器
    reg               rollover_low;  // 低位计数器溢出标志
    
    // 计数器最大值常量
    localparam [WIDTH/2-1:0] MAX_COUNT_HALF = {(WIDTH/2){1'b1}};
    
    // 控制状态编码
    localparam [1:0] STATE_RESET = 2'b00;
    localparam [1:0] STATE_ENABLE = 2'b01;
    localparam [1:0] STATE_DISABLE = 2'b10;
    
    // 低位计数器逻辑 - 第一级流水线
    always @(posedge clk) begin
        // 组合控制信号
        case ({!rst_n, enable})
            2'b10, 2'b11: begin // 复位状态（优先级最高）
                counter_low <= '0;
                rollover_low <= 1'b0;
            end
            2'b01: begin // 使能状态
                counter_low <= (counter_low == MAX_COUNT_HALF) ? '0 : counter_low + 1'b1;
                rollover_low <= (counter_low == MAX_COUNT_HALF);
            end
            2'b00: begin // 禁用状态
                counter_low <= counter_low; // 保持当前值
                rollover_low <= 1'b0;
            end
            default: begin // 未定义状态(不会发生)
                counter_low <= counter_low;
                rollover_low <= rollover_low;
            end
        endcase
    end
    
    // 高位计数器逻辑 - 第二级流水线
    always @(posedge clk) begin
        case ({!rst_n, enable & rollover_low})
            2'b10, 2'b11: begin // 复位状态
                counter_high <= '0;
            end
            2'b01: begin // 使能且低位溢出
                counter_high <= (counter_high == MAX_COUNT_HALF) ? '0 : counter_high + 1'b1;
            end
            2'b00: begin // 无操作状态
                counter_high <= counter_high; // 保持当前值
            end
            default: begin
                counter_high <= counter_high;
            end
        endcase
    end
    
    // 计时器输出逻辑 - 最终级
    always @(posedge clk) begin
        case ({!rst_n, enable})
            2'b10, 2'b11: begin // 复位状态
                timer_out <= 1'b0;
            end
            2'b01: begin // 使能状态
                timer_out <= (counter_high == MAX_COUNT_HALF) && (counter_low == MAX_COUNT_HALF);
            end
            2'b00: begin // 禁用状态
                timer_out <= 1'b0;
            end
            default: begin
                timer_out <= 1'b0;
            end
        endcase
    end

endmodule