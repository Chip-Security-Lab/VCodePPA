module adder_with_carry (
    input  [3:0] a, b,
    input        cin,
    output [3:0] sum,
    output       carry
);

    wire [3:0] g, p;
    wire [1:0] g1, p1;
    wire g2, p2;
    wire [3:0] c;

    // Generate and propagate module
    gp_generator gp_gen (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // First level Brent-Kung tree
    bk_level1 bk_l1 (
        .g(g),
        .p(p),
        .cin(cin),
        .g1(g1),
        .p1(p1)
    );

    // Second level Brent-Kung tree
    bk_level2 bk_l2 (
        .g1(g1),
        .p1(p1),
        .cin(cin),
        .g2(g2),
        .p2(p2)
    );

    // Carry computation
    carry_generator carry_gen (
        .g(g),
        .p(p),
        .g1(g1),
        .p1(p1),
        .g2(g2),
        .p2(p2),
        .cin(cin),
        .c(c)
    );

    // Sum computation
    sum_generator sum_gen (
        .p(p),
        .c(c),
        .sum(sum)
    );

    assign carry = c[3];

endmodule

module gp_generator (
    input  [3:0] a, b,
    output [3:0] g, p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

module bk_level1 (
    input  [3:0] g, p,
    input        cin,
    output [1:0] g1, p1
);
    assign g1[0] = g[0] | (p[0] & cin);
    assign p1[0] = p[0];
    assign g1[1] = g[2] | (p[2] & g[1]);
    assign p1[1] = p[2] & p[1];
endmodule

module bk_level2 (
    input  [1:0] g1, p1,
    input        cin,
    output       g2, p2
);
    assign g2 = g1[1] | (p1[1] & g1[0]);
    assign p2 = p1[1] & p1[0];
endmodule

module carry_generator (
    input  [3:0] g, p,
    input  [1:0] g1, p1,
    input        g2, p2,
    input        cin,
    output [3:0] c
);
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g1[1] | (p1[1] & g1[0]);
    assign c[3] = g2 | (p2 & cin);
endmodule

module sum_generator (
    input  [3:0] p, c,
    output [3:0] sum
);
    assign sum = p ^ c;
endmodule