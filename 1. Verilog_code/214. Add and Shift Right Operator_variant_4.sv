//SystemVerilog
module add_signed_divide (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] sum,
    output signed [7:0] quotient
);

    // 实例化加法子模块
    adder u_adder (
        .a(a),
        .c(c),
        .sum(sum)
    );

    // 实例化除法子模块
    divider u_divider (
        .a(a),
        .b(b),
        .quotient(quotient)
    );

endmodule

// 加法子模块
module adder (
    input signed [7:0] a,
    input signed [7:0] c,
    output signed [15:0] sum
);
    assign sum = a + c;
endmodule

// 除法子模块
module divider (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient
);
    assign quotient = a / b;
endmodule