//SystemVerilog
module pwm_gen(
    input clk,
    input reset,
    input [7:0] duty,
    output pwm_out
);
    // 内部信号定义
    reg [7:0] counter_reg;
    wire [7:0] next_counter;
    reg pwm_out_reg;
    
    // 组合逻辑部分 - 计算下一个计数值
    assign next_counter = counter_reg + 1'b1;
    
    // 组合逻辑部分 - 使用显式多路复用器结构实现PWM输出
    assign pwm_out = pwm_out_reg;
    
    // 时序逻辑部分 - 仅在时钟边沿更新寄存器
    always @(posedge clk) begin
        if (reset) begin
            counter_reg <= 8'h00;
            pwm_out_reg <= 1'b0;
        end
        else begin
            counter_reg <= next_counter;
            case (counter_reg < duty)
                1'b1: pwm_out_reg <= 1'b1;
                1'b0: pwm_out_reg <= 1'b0;
                default: pwm_out_reg <= 1'b0;
            endcase
        end
    end
endmodule