//SystemVerilog
`timescale 1ns/1ps

// 顶层模块
module DelayedOR(
    input [7:0] x, y,  // 扩展为8位输入
    output [7:0] z     // 扩展为8位输出
);
    wire [7:0] div_result;
    
    // 实例化SRT除法器
    SRTDivider u_srt_divider (
        .dividend(x),
        .divisor(y),
        .quotient(div_result)
    );
    
    DelayElement #(
        .DELAY_NS(3)
    ) u_delay (
        .in(div_result),
        .out(z)
    );
endmodule

// SRT除法器实现
module SRTDivider(
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient
);
    reg [7:0] partial_remainder;
    reg [7:0] abs_divisor;
    reg [2:0] iteration;
    reg [1:0] q_digit;
    reg dividend_sign, divisor_sign, result_sign;
    
    always @(*) begin
        // 初始化
        dividend_sign = dividend[7];
        divisor_sign = divisor[7];
        result_sign = dividend_sign ^ divisor_sign;
        
        // 取绝对值
        abs_divisor = divisor_sign ? (~divisor + 1'b1) : divisor;
        partial_remainder = dividend_sign ? (~dividend + 1'b1) : dividend;
        quotient = 8'b0;
        
        // 检查除数为0的情况
        if (divisor == 8'b0) begin
            quotient = 8'hFF;  // 设置为最大值表示无穷大
        end else begin
            // SRT除法算法实现
            for (iteration = 0; iteration < 4; iteration = iteration + 1) begin
                // 确定部分商数字(-1, 0, 1)
                if (partial_remainder >= (abs_divisor << 1))
                    q_digit = 2'b10;  // 表示2
                else if (partial_remainder >= abs_divisor)
                    q_digit = 2'b01;  // 表示1
                else if (partial_remainder < -abs_divisor)
                    q_digit = 2'b11;  // 表示-1
                else
                    q_digit = 2'b00;  // 表示0
                
                // 更新部分余数
                case (q_digit)
                    2'b10: partial_remainder = partial_remainder - (abs_divisor << 1);
                    2'b01: partial_remainder = partial_remainder - abs_divisor;
                    2'b11: partial_remainder = partial_remainder + abs_divisor;
                    default: partial_remainder = partial_remainder;
                endcase
                
                // 移位并插入商位
                quotient = quotient << 2;
                quotient[1:0] = q_digit;
                
                // 部分余数左移
                partial_remainder = partial_remainder << 2;
            end
            
            // 应用符号位
            if (result_sign)
                quotient = ~quotient + 1'b1;
        end
    end
endmodule

// 可参数化延迟元素子模块
module DelayElement #(
    parameter DELAY_NS = 1
)(
    input [7:0] in,    // 扩展为8位输入
    output [7:0] out   // 扩展为8位输出
);
    assign #(DELAY_NS) out = in;
endmodule