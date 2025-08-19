// PG Generator Module
module pg_generator (
    input  [3:0] a, b,
    output [3:0] p, g
);
    assign p = a ^ b;
    assign g = a & b;
endmodule

// Carry Lookahead Unit
module carry_lookahead_unit (
    input  [3:0] p, g,
    output [3:0] c
);
    wire [3:0] c1;
    
    assign c1[0] = g[0];
    assign c1[1] = g[1] | (p[1] & g[0]);
    assign c1[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c1[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    assign c = c1;
endmodule

// Sum Generator Module
module sum_generator (
    input  [3:0] p, c,
    output [3:0] sum
);
    assign sum = p ^ c;
endmodule

// Top Level Module
module carry_lookahead_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g, c;
    
    pg_generator pg_gen (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );
    
    carry_lookahead_unit clu (
        .p(p),
        .g(g),
        .c(c)
    );
    
    sum_generator sum_gen (
        .p(p),
        .c(c),
        .sum(sum)
    );
    
    assign carry = c[3];
endmodule