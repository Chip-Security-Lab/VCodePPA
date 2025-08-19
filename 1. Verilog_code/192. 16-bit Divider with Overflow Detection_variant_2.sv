//SystemVerilog
module divider_16bit (
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg overflow
);

    reg [15:0] x0, x1, x2;               // 牛顿迭代中间值
    reg [31:0] temp_mul1, temp_mul2;     // 乘法临时结果
    reg [15:0] divisor_reg;              // 缓存除数
    reg [15:0] dividend_reg;             // 缓存被除数

    always @(*) begin
        if (divisor == 0) begin
            overflow = 1;
            quotient = 0;
            remainder = 0;
        end else begin
            overflow = 0;
            divisor_reg = divisor;
            dividend_reg = dividend;
            
            // 牛顿-拉弗森迭代法求倒数
            // 初始估计值: x0 = 1/(2^n) 其中 n是除数最高位的位置
            if (divisor_reg[15])
                x0 = 16'h0001;          // 如果最高位为1，初始值设为1/2^15
            else if (divisor_reg[14])
                x0 = 16'h0002;          // 如果第14位为1，初始值设为1/2^14
            else if (divisor_reg[13])
                x0 = 16'h0004;
            else if (divisor_reg[12])
                x0 = 16'h0008;
            else if (divisor_reg[11])
                x0 = 16'h0010;
            else if (divisor_reg[10])
                x0 = 16'h0020;
            else if (divisor_reg[9])
                x0 = 16'h0040;
            else if (divisor_reg[8])
                x0 = 16'h0080;
            else if (divisor_reg[7])
                x0 = 16'h0100;
            else if (divisor_reg[6])
                x0 = 16'h0200;
            else if (divisor_reg[5])
                x0 = 16'h0400;
            else if (divisor_reg[4])
                x0 = 16'h0800;
            else if (divisor_reg[3])
                x0 = 16'h1000;
            else if (divisor_reg[2])
                x0 = 16'h2000;
            else if (divisor_reg[1])
                x0 = 16'h4000;
            else
                x0 = 16'h8000;
                
            // 第一次迭代: x1 = x0 * (2 - divisor * x0)
            temp_mul1 = divisor_reg * x0;
            x1 = ((16'h0002 - temp_mul1[15:0]) * x0) >> 1;
            
            // 第二次迭代: x2 = x1 * (2 - divisor * x1)
            temp_mul2 = divisor_reg * x1;
            x2 = ((16'h0002 - temp_mul2[15:0]) * x1) >> 1;
            
            // 计算商: quotient = dividend * (1/divisor)
            quotient = (dividend_reg * x2) >> 15;
            
            // 计算余数: remainder = dividend - quotient * divisor
            remainder = dividend_reg - (quotient * divisor_reg);
            
            // 处理可能的余数修正
            if (remainder >= divisor_reg) begin
                quotient = quotient + 1;
                remainder = remainder - divisor_reg;
            end
        end
    end

endmodule