//SystemVerilog
module divider_16bit_nba (
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

    reg [15:0] temp_quotient;
    reg [15:0] temp_remainder;
    reg [15:0] abs_dividend;
    reg [15:0] abs_divisor;
    reg quot_sign, rem_sign;
    integer i;

    always @(*) begin
        // 处理被除数和除数可能为0的特殊情况
        if (divisor == 16'b0) begin
            // 除以0，设置为全1（可根据实际需求调整）
            quotient = 16'hFFFF;
            remainder = dividend;
        end else begin
            // 初始化
            abs_dividend = dividend[15] ? (~dividend + 1'b1) : dividend;
            abs_divisor = divisor[15] ? (~divisor + 1'b1) : divisor;
            quot_sign = dividend[15] ^ divisor[15];
            rem_sign = dividend[15];
            
            temp_remainder = 16'b0;
            temp_quotient = 16'b0;
            
            // 非恢复余数除法算法
            for (i = 15; i >= 0; i = i - 1) begin
                // 左移余数并引入被除数的下一位
                temp_remainder = (temp_remainder << 1) | ((abs_dividend >> i) & 1'b1);
                
                // 使用补码加法实现减法
                if (temp_remainder >= abs_divisor) begin
                    temp_remainder = temp_remainder + (~abs_divisor + 1'b1); // temp_remainder - abs_divisor
                    temp_quotient = temp_quotient | (1'b1 << i);
                end
            end
            
            // 应用符号
            quotient = quot_sign ? (~temp_quotient + 1'b1) : temp_quotient;
            remainder = rem_sign ? (~temp_remainder + 1'b1) : temp_remainder;
        end
    end

endmodule