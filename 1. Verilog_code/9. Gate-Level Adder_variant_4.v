module parallel_prefix_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);

    // Generate and propagate signals
    wire [3:0] p, g;
    assign p = a ^ b;
    assign g = a & b;

    // Stage 1: Generate first level of prefix computation
    wire [3:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];

    // Stage 2: Generate second level of prefix computation
    wire [3:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];

    // Stage 3: Generate final carry and sum
    wire [3:0] c;
    assign c[0] = 1'b0;
    assign c[1] = g2[0];
    assign c[2] = g2[1];
    assign c[3] = g2[2];

    assign sum = p ^ {c[2:0], 1'b0};
    assign carry = g2[3] | (p2[3] & g2[1]);

endmodule