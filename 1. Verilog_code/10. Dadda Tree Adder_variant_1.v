module dadda_adder (
    input  [3:0] a, b,
    output [3:0] sum
);

    wire [3:0] g, p;
    wire [3:0] g1, p1;
    wire [3:0] g2, p2;

    gp_generator gp_gen (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    stage1_calc stage1 (
        .g(g),
        .p(p),
        .g1(g1),
        .p1(p1)
    );

    stage2_calc stage2 (
        .g1(g1),
        .p1(p1),
        .g2(g2),
        .p2(p2)
    );

    sum_calculator sum_calc (
        .p(p),
        .g2(g2),
        .sum(sum)
    );

endmodule

module gp_generator (
    input  [3:0] a, b,
    output [3:0] g, p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

module stage1_calc (
    input  [3:0] g, p,
    output [3:0] g1, p1
);
    wire [3:0] pg;
    assign pg = p & g;
    
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | pg[0];
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]) | (p[2] & pg[0]);
    assign p1[2] = p[2] & p1[1];
    assign g1[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p1[2] & g[0]);
    assign p1[3] = p[3] & p1[2];
endmodule

module stage2_calc (
    input  [3:0] g1, p1,
    output [3:0] g2, p2
);
    wire [3:0] p1g1;
    assign p1g1 = p1 & g1;
    
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | p1g1[0];
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | p1g1[1];
    assign p2[3] = p1[3] & p1[1];
endmodule

module sum_calculator (
    input  [3:0] p, g2,
    output [3:0] sum
);
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g2[0];
    assign sum[2] = p[2] ^ g2[1];
    assign sum[3] = p[3] ^ g2[2];
endmodule