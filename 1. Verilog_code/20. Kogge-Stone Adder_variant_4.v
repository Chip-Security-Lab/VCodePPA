module prefix_level1(
    input [3:0] g, p,
    output [3:0] g1, p1
);
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
endmodule

module prefix_level2(
    input [3:0] g1, p1,
    output [3:0] g2, p2
);
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[3]);
    assign p2[2] = p1[2] & p1[3];
    assign g2[3] = g1[3];
    assign p2[3] = p1[3];
endmodule

module carry_gen(
    input [3:0] g2, p2,
    output [4:0] c
);
    assign c[0] = 1'b0;
    assign c[1] = g2[0];
    assign c[2] = g2[1] | (p2[1] & g2[0]);
    assign c[3] = g2[2] | (p2[2] & g2[1]);
    assign c[4] = g2[3] | (p2[3] & g2[2]);
endmodule

module kogge_stone_adder(
    input [3:0] a, b,
    output [3:0] sum
);
    wire [3:0] p = a ^ b;
    wire [3:0] g = a & b;
    wire [3:0] g1, p1, g2, p2;
    wire [4:0] c;

    prefix_level1 pl1(
        .g(g),
        .p(p),
        .g1(g1),
        .p1(p1)
    );

    prefix_level2 pl2(
        .g1(g1),
        .p1(p1),
        .g2(g2),
        .p2(p2)
    );

    carry_gen cg(
        .g2(g2),
        .p2(p2),
        .c(c)
    );

    assign sum = p ^ c[3:0];
endmodule