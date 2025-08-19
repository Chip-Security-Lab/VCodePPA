module gate_level_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g;
    wire [3:0] c;
    
    // Parallel prefix adder implementation
    propagate_gen pg_unit (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );
    
    // Kogge-Stone parallel prefix carry computation
    carry_logic carry_unit (
        .p(p),
        .g(g),
        .c(c)
    );
    
    // Sum computation
    sum_logic sum_unit (
        .p(p),
        .c(c),
        .sum(sum)
    );
    
    assign carry = c[3];
endmodule

module propagate_gen (
    input  [3:0] a, b,
    output [3:0] p, g
);
    // XOR gates for propagate signals
    assign p = a ^ b;
    
    // AND gates for generate signals  
    assign g = a & b;
endmodule

module carry_logic (
    input  [3:0] p, g,
    output [3:0] c
);
    wire [3:0] g1, p1;
    wire [3:0] g2, p2;
    
    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    
    // Second level
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    
    // Final carry computation
    assign c[0] = g2[0];
    assign c[1] = g2[1];
    assign c[2] = g2[2];
    assign c[3] = g2[3];
endmodule

module sum_logic (
    input  [3:0] p, c,
    output [3:0] sum
);
    // Sum computation using XOR
    assign sum = p ^ {1'b0, c[2:0]};
endmodule