//SystemVerilog
//IEEE 1364-2005

// 顶层模块
module dither_pwm #(parameter N=8)(
    input clk, 
    input [N-1:0] din,
    output pwm
);
    // 内部连接信号
    wire [N-1:0] error_value;
    wire [N-1:0] next_error;
    wire overflow_flag;

    // 误差累积与计算子模块
    error_accumulator #(
        .WIDTH(N)
    ) u_error_accumulator (
        .clk(clk),
        .din(din),
        .current_error(error_value),
        .next_error(next_error),
        .overflow(overflow_flag)
    );

    // PWM输出寄存器子模块
    output_register #(
        .WIDTH(N)
    ) u_output_register (
        .clk(clk),
        .overflow(overflow_flag),
        .next_error(next_error),
        .pwm_out(pwm),
        .error_out(error_value)
    );
endmodule

// 误差累积与计算子模块
module error_accumulator #(parameter WIDTH=8)(
    input clk,
    input [WIDTH-1:0] din,
    input [WIDTH-1:0] current_error,
    output [WIDTH-1:0] next_error,
    output overflow
);
    // 执行误差扩散算法计算
    wire [WIDTH:0] sum = din + current_error;
    
    // 提取溢出位和下一个误差值
    assign overflow = sum[WIDTH];
    assign next_error = sum[WIDTH-1:0];
endmodule

// PWM输出寄存器子模块
module output_register #(parameter WIDTH=8)(
    input clk,
    input overflow,
    input [WIDTH-1:0] next_error,
    output reg pwm_out,
    output reg [WIDTH-1:0] error_out
);
    // 更新PWM输出和误差寄存器
    always @(posedge clk) begin
        pwm_out <= overflow;
        error_out <= next_error;
    end
endmodule