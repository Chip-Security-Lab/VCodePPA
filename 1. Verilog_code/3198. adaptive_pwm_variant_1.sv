//SystemVerilog
module adaptive_pwm #(
    parameter WIDTH = 8
)(
    input clk,
    input feedback,
    output reg pwm
);
    reg [WIDTH-1:0] duty_cycle;
    reg [WIDTH-1:0] counter;
    
    // 提取共同条件变量
    reg [1:0] adjust_mode;
    
    always @(*) begin
        // 确定调整模式
        if (feedback && duty_cycle < {WIDTH{1'b1}})
            adjust_mode = 2'b01;      // 增加占空比
        else if (!feedback && duty_cycle > {WIDTH{1'b0}})
            adjust_mode = 2'b10;      // 减少占空比
        else
            adjust_mode = 2'b00;      // 保持不变
    end
    
    always @(posedge clk) begin
        // 计数器增加和PWM输出更新
        counter <= counter + 1'b1;
        pwm <= (counter < duty_cycle);
        
        // 使用case语句替代if-else级联
        case (adjust_mode)
            2'b01: duty_cycle <= duty_cycle + 1'b1;  // 增加占空比
            2'b10: duty_cycle <= duty_cycle - 1'b1;  // 减少占空比
            default: duty_cycle <= duty_cycle;       // 保持不变
        endcase
    end
endmodule