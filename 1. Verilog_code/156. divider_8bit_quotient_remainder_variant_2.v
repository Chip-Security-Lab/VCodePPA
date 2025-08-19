module divider_8bit_quotient_remainder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);

    // 除法运算子模块
    divider_core u_divider_core (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module divider_core (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // 除法运算逻辑
    always @(*) begin
        quotient = dividend / divisor;
        remainder = dividend % divisor;
    end

endmodule