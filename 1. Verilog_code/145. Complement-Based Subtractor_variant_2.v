// Kogge-Stone加法器子模块
module kogge_stone_adder(
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);
    wire [7:0] p, g;
    wire [7:0] p1, g1;
    wire [7:0] p2, g2;
    wire [7:0] p3, g3;
    wire [7:0] c;

    // 生成和传播信号
    assign p = a ^ b;
    assign g = a & b;

    // 第一级
    assign p1[0] = p[0];
    assign g1[0] = g[0];
    assign p1[1] = p[1];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[2] = p[2];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[3] = p[3];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[4] = p[4];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[5] = p[5];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[6] = p[6];
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[7] = p[7];
    assign g1[7] = g[7] | (p[7] & g[6]);

    // 第二级
    assign p2[0] = p1[0];
    assign g2[0] = g1[0];
    assign p2[1] = p1[1];
    assign g2[1] = g1[1];
    assign p2[2] = p1[2] & p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[1]);
    assign p2[3] = p1[3] & p1[2];
    assign g2[3] = g1[3] | (p1[3] & g1[2]);
    assign p2[4] = p1[4] & p1[3];
    assign g2[4] = g1[4] | (p1[4] & g1[3]);
    assign p2[5] = p1[5] & p1[4];
    assign g2[5] = g1[5] | (p1[5] & g1[4]);
    assign p2[6] = p1[6] & p1[5];
    assign g2[6] = g1[6] | (p1[6] & g1[5]);
    assign p2[7] = p1[7] & p1[6];
    assign g2[7] = g1[7] | (p1[7] & g1[6]);

    // 第三级
    assign p3[0] = p2[0];
    assign g3[0] = g2[0];
    assign p3[1] = p2[1];
    assign g3[1] = g2[1];
    assign p3[2] = p2[2];
    assign g3[2] = g2[2];
    assign p3[3] = p2[3];
    assign g3[3] = g2[3];
    assign p3[4] = p2[4] & p2[2];
    assign g3[4] = g2[4] | (p2[4] & g2[2]);
    assign p3[5] = p2[5] & p2[3];
    assign g3[5] = g2[5] | (p2[5] & g2[3]);
    assign p3[6] = p2[6] & p2[4];
    assign g3[6] = g2[6] | (p2[6] & g2[4]);
    assign p3[7] = p2[7] & p2[5];
    assign g3[7] = g2[7] | (p2[7] & g2[5]);

    // 进位计算
    assign c[0] = 1'b0;
    assign c[1] = g3[0];
    assign c[2] = g3[1];
    assign c[3] = g3[2];
    assign c[4] = g3[3];
    assign c[5] = g3[4];
    assign c[6] = g3[5];
    assign c[7] = g3[6];

    // 最终和计算
    assign sum = p ^ c;

endmodule

// 补码转换子模块
module complement_converter (
    input wire [7:0] in,
    output wire [7:0] out
);
    assign out = ~in + 1;
endmodule

// 顶层减法器模块
module subtractor_complement (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);

    wire [7:0] b_complement;

    // 实例化补码转换模块
    complement_converter comp_conv (
        .in(b),
        .out(b_complement)
    );

    // 实例化Kogge-Stone加法器模块
    kogge_stone_adder add (
        .a(a),
        .b(b_complement),
        .sum(res)
    );

endmodule