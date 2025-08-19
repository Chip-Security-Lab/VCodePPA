module kogge_stone_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g;
    wire [3:0] c;
    
    // Stage 1: Generate P and G
    assign p = a ^ b;
    assign g = a & b;
    
    // Stage 2: Kogge-Stone prefix computation
    wire [3:0] p1, g1;
    wire [3:0] p2, g2;
    
    // First level
    assign p1[0] = p[0];
    assign g1[0] = g[0];
    assign p1[1] = p[1] & p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[2] = p[2] & p[1];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[3] = p[3] & p[2];
    assign g1[3] = g[3] | (p[3] & g[2]);
    
    // Second level
    assign p2[0] = p1[0];
    assign g2[0] = g1[0];
    assign p2[1] = p1[1];
    assign g2[1] = g1[1];
    assign p2[2] = p1[2] & p1[0];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    
    // Final carry computation
    assign c[0] = g2[0];
    assign c[1] = g2[1];
    assign c[2] = g2[2];
    assign c[3] = g2[3];
    
    // Sum generation
    assign sum = p ^ c;
    assign carry = c[3];

endmodule