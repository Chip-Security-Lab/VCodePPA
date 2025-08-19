module subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);

    wire [7:0] b_comp;
    wire [7:0] sum;
    wire cout;

    // 补码计算模块
    twos_complement_8bit comp_unit (
        .in(b),
        .out(b_comp)
    );

    // 加法器模块
    carry_lookahead_adder_8bit adder (
        .a(a),
        .b(b_comp),
        .cin(1'b0),
        .sum(sum),
        .cout(cout)
    );

    assign diff = sum;

endmodule

module twos_complement_8bit (
    input [7:0] in,
    output [7:0] out
);
    assign out = ~in + 1'b1;
endmodule

module carry_lookahead_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);

    wire [7:0] g, p;
    wire [8:0] c;

    // 生成和传播信号计算模块
    generate_propagate_8bit gp_unit (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // 先行进位计算模块
    carry_lookahead_8bit cla_unit (
        .g(g),
        .p(p),
        .cin(cin),
        .c(c)
    );

    // 和计算模块
    sum_8bit sum_unit (
        .p(p),
        .c(c[7:0]),
        .sum(sum)
    );

    assign cout = c[8];

endmodule

module generate_propagate_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] g,
    output [7:0] p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

module carry_lookahead_8bit (
    input [7:0] g,
    input [7:0] p,
    input cin,
    output [8:0] c
);
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
endmodule

module sum_8bit (
    input [7:0] p,
    input [7:0] c,
    output [7:0] sum
);
    assign sum = p ^ c;
endmodule