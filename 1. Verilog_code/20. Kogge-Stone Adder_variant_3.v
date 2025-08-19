module brent_kung_adder(
    input [5:0] a, b,
    output [5:0] sum
);

    // Generate and propagate signals
    wire [5:0] g = a & b;
    wire [5:0] p = a ^ b;
    
    // Level 1
    wire [5:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    
    // Level 2
    wire [5:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    
    // Level 3
    wire [5:0] g3, p3;
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    
    // Level 4
    wire [5:0] g4, p4;
    assign g4[0] = g3[0];
    assign p4[0] = p3[0];
    assign g4[1] = g3[1];
    assign p4[1] = p3[1];
    assign g4[2] = g3[2];
    assign p4[2] = p3[2];
    assign g4[3] = g3[3];
    assign p4[3] = p3[3];
    assign g4[4] = g3[4];
    assign p4[4] = p3[4];
    assign g4[5] = g3[5] | (p3[5] & g3[0]);
    assign p4[5] = p3[5] & p3[0];
    
    // Final carries
    wire [6:0] c = {g4, 1'b0};
    
    // Sum computation
    assign sum = p ^ c[5:0];

endmodule