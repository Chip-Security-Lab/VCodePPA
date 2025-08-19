//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module dither_pwm #(parameter N=8)(
    input clk, 
    input [N-1:0] din,
    output pwm
);
    wire [N:0] next_err;
    wire [N-1:0] current_err;
    wire next_pwm;
    
    // 误差计算子模块实例化
    error_accumulator #(.N(N)) u_error_acc (
        .din(din),
        .prev_err(current_err),
        .next_err(next_err),
        .pwm_bit(next_pwm)
    );
    
    // 状态寄存器子模块实例化
    state_register #(.N(N)) u_state_reg (
        .clk(clk),
        .next_err(next_err),
        .next_pwm(next_pwm),
        .current_err(current_err),
        .pwm(pwm)
    );
    
endmodule

// 误差计算子模块 - 处理误差累加和输出位生成
module error_accumulator #(parameter N=8)(
    input [N-1:0] din,
    input [N-1:0] prev_err,
    output [N:0] next_err,
    output pwm_bit
);
    // 计算新的误差和PWM输出位
    assign next_err = din + prev_err;
    assign pwm_bit = next_err[N];
    
endmodule

// 状态寄存器子模块 - 处理时序和状态存储
module state_register #(parameter N=8)(
    input clk,
    input [N:0] next_err,
    input next_pwm,
    output reg [N-1:0] current_err,
    output reg pwm
);
    // 时钟上升沿时更新状态
    always @(posedge clk) begin
        pwm <= next_pwm;
        current_err <= next_err[N-1:0];
    end
    
endmodule