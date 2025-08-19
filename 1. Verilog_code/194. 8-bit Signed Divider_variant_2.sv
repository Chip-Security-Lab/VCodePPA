//SystemVerilog
module divider_signed_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [15:0] x, d;
    reg [15:0] f1, f2;
    reg [15:0] x_next, d_next;
    reg [2:0] i;
    reg [7:0] abs_dividend, abs_divisor;
    reg dividend_sign, divisor_sign;
    
    always @(*) begin
        // 处理符号
        dividend_sign = dividend[7];
        divisor_sign = divisor[7];
        
        // 取绝对值
        abs_dividend = dividend_sign ? (~dividend + 8'b1) : dividend;
        abs_divisor = divisor_sign ? (~divisor + 8'b1) : divisor;
        
        // 初始化
        x = {8'b0, abs_dividend};
        d = {8'b0, abs_divisor};
        
        // Goldschmidt迭代
        for (i = 0; i < 3; i = i + 1) begin
            // 计算因子 f = 2 - d
            f1 = 16'h0200 - {8'b0, d[15:8]};
            
            // 更新 x 和 d
            x_next = (x * f1) >> 8;
            d_next = (d * f1) >> 8;
            
            x = x_next;
            d = d_next;
        end
        
        // 计算商和余数
        if (divisor == 8'b0) begin
            // 除以零处理
            quotient = 8'hFF;
            remainder = 8'hFF;
        end else begin
            // 计算商 x/d ≈ x 当 d ≈ 1
            quotient = x[7:0];
            
            // 恢复符号
            if (dividend_sign ^ divisor_sign)
                quotient = ~quotient + 8'b1;
                
            // 计算余数 (余数 = 被除数 - 商*除数)
            if (dividend_sign ^ divisor_sign) begin
                remainder = dividend - (quotient * divisor);
            end else begin
                remainder = dividend - (quotient * divisor);
            end
        end
    end

endmodule