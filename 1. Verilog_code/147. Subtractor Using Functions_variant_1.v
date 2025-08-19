module twos_complement (
    input wire [7:0] in,
    output wire [7:0] out
);
    assign out = ~in + 1'b1;
endmodule

module adder_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire carry_out,
    output wire [7:0] sum
);
    assign {carry_out, sum} = a + b;
endmodule

module subtractor_function (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);

    wire [7:0] b_comp;    // 减数的补码
    wire carry_out;       // 进位输出

    // 实例化补码计算模块
    twos_complement comp_inst (
        .in(b),
        .out(b_comp)
    );

    // 实例化加法器模块
    adder_8bit adder_inst (
        .a(a),
        .b(b_comp),
        .carry_out(carry_out),
        .sum(res)
    );

endmodule