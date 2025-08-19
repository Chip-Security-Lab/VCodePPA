//SystemVerilog
module SatDiv(
    input [7:0] a, b,
    output reg [7:0] q
);
    // 检查除数是否为零的优化信号
    wire b_is_zero;

    // 用OR归约操作符检测除数是否为零
    assign b_is_zero = ~|b;

    // 二进制长除法算法实现
    reg [7:0] remainder;
    reg [7:0] quotient;
    integer i;

    always @(*) begin
        if (b_is_zero) begin
            q = 8'hFF; // 除数为零时输出
        end else begin
            remainder = a; // 被除数
            quotient = 0; // 初始商

            // 二进制长除法
            for (i = 7; i >= 0; i = i - 1) begin
                remainder = remainder << 1; // 左移被除数
                remainder[0] = b[i]; // 将当前位放入余数的最低位
                if (remainder >= b) begin
                    remainder = remainder - b; // 减去除数
                    quotient[i] = 1; // 商的当前位为1
                end else begin
                    quotient[i] = 0; // 商的当前位为0
                end
            end
            q = quotient; // 输出商
        end
    end
endmodule