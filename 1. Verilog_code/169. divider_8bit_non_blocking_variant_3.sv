//SystemVerilog
module divider_8bit_non_blocking (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);

    // 除法控制模块
    divider_control u_control (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// 除法控制模块
module divider_control (
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient,
    output [7:0] remainder
);

    // 除法计算模块
    divider_calc u_calc (
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// 除法计算模块
module divider_calc (
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