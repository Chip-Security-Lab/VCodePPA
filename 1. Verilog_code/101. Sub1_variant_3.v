// 补码计算子模块
module complement_calc(
    input [7:0] b,
    output [7:0] b_comp
);
    assign b_comp = ~b + 1'b1;
endmodule

// 加法器子模块
module adder(
    input [7:0] a,
    input [7:0] b_comp,
    output [7:0] sum,
    output carry_out
);
    assign {carry_out, sum} = a + b_comp;
endmodule

// 顶层模块
module Sub1(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    wire [7:0] b_comp;
    wire [7:0] sum;
    wire carry_out;

    // 实例化补码计算模块
    complement_calc comp_inst(
        .b(b),
        .b_comp(b_comp)
    );

    // 实例化加法器模块
    adder add_inst(
        .a(a),
        .b_comp(b_comp),
        .sum(sum),
        .carry_out(carry_out)
    );

    // 输出结果
    assign result = sum;

endmodule