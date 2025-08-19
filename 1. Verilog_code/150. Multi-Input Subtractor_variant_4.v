// 顶层模块
module adder_subtractor_top (
    input wire [3:0] a,   // 被减数 1
    input wire [3:0] b,   // 被减数 2
    input wire [3:0] c,   // 被减数 3
    input wire [3:0] d,   // 减数
    output wire [3:0] res // 差
);

    wire [3:0] sum_ab;    // a+b的结果
    wire [3:0] sum_abc;   // a+b+c的结果
    wire [3:0] d_comp;    // d的补码

    // 实例化加法器链模块
    adder_chain adder_chain_inst (
        .a(a),
        .b(b),
        .c(c),
        .sum_ab(sum_ab),
        .sum_abc(sum_abc)
    );

    // 实例化补码生成模块
    complement_generator comp_gen_inst (
        .d(d),
        .d_comp(d_comp)
    );

    // 实例化最终减法模块
    final_subtractor final_sub_inst (
        .sum_abc(sum_abc),
        .d_comp(d_comp),
        .res(res)
    );

endmodule

// 加法器链模块 - 负责连续加法操作
module adder_chain (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] sum_ab,
    output wire [3:0] sum_abc
);

    // 第一级加法
    adder_2_input adder_ab (
        .a(a),
        .b(b),
        .sum(sum_ab)
    );

    // 第二级加法
    adder_2_input adder_abc (
        .a(sum_ab),
        .b(c),
        .sum(sum_abc)
    );

endmodule

// 补码生成模块 - 负责生成减数的补码
module complement_generator (
    input wire [3:0] d,
    output wire [3:0] d_comp
);

    assign d_comp = ~d + 1'b1;

endmodule

// 最终减法模块 - 负责执行最终的减法操作
module final_subtractor (
    input wire [3:0] sum_abc,
    input wire [3:0] d_comp,
    output wire [3:0] res
);

    adder_2_input sub_final (
        .a(sum_abc),
        .b(d_comp),
        .sum(res)
    );

endmodule

// 两输入加法器子模块
module adder_2_input (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] sum
);

    assign sum = a + b;

endmodule