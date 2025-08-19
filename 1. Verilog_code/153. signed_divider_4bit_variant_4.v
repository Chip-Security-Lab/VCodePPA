module signed_divider_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    // 实例化除法运算子模块
    div_core div_core_inst (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// 除法运算核心子模块
module div_core (
    input signed [3:0] dividend,
    input signed [3:0] divisor,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    // 符号处理
    wire sign_dividend = dividend[3];
    wire sign_divisor = divisor[3];
    wire [3:0] abs_dividend = sign_dividend ? -dividend : dividend;
    wire [3:0] abs_divisor = sign_divisor ? -divisor : divisor;

    // 无符号除法运算
    wire [3:0] abs_quotient;
    wire [3:0] abs_remainder;
    
    assign abs_quotient = abs_dividend / abs_divisor;
    assign abs_remainder = abs_dividend % abs_divisor;

    // 结果符号处理
    assign quotient = (sign_dividend ^ sign_divisor) ? -abs_quotient : abs_quotient;
    assign remainder = sign_dividend ? -abs_remainder : abs_remainder;

endmodule