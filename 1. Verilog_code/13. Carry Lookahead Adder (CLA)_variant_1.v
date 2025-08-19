module cla_adder(
    input [4:0] a, b,
    input cin,
    output [4:0] sum,
    output cout
);

    wire [4:0] g, p;
    wire [5:0] c;

    gen_prop_gen gpg(
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    carry_gen cg(
        .g(g),
        .p(p),
        .cin(cin),
        .c(c)
    );

    sum_gen sg(
        .a(a),
        .b(b),
        .c(c[4:0]),
        .sum(sum)
    );

    assign cout = c[5];

endmodule

module gen_prop_gen(
    input [4:0] a, b,
    output [4:0] g, p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

module carry_gen(
    input [4:0] g, p,
    input cin,
    output [5:0] c
);
    wire [4:0] t;
    
    assign t[0] = p[0] & cin;
    assign t[1] = p[1] & (g[0] | t[0]);
    assign t[2] = p[2] & (g[1] | t[1]);
    assign t[3] = p[3] & (g[2] | t[2]);
    assign t[4] = p[4] & (g[3] | t[3]);
    
    assign c[0] = cin;
    assign c[1] = g[0] | t[0];
    assign c[2] = g[1] | t[1];
    assign c[3] = g[2] | t[2];
    assign c[4] = g[3] | t[3];
    assign c[5] = g[4] | t[4];
endmodule

module sum_gen(
    input [4:0] a, b, c,
    output [4:0] sum
);
    assign sum = a ^ b ^ c;
endmodule