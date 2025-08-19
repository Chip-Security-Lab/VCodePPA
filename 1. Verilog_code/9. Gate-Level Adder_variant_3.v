module brent_kung_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    // Stage 1: Generate and Propagate
    wire [3:0] p, g;
    assign p = a ^ b;
    assign g = a & b;

    // Stage 2: Brent-Kung Tree
    wire [1:0] g_01, p_01;
    wire [1:0] g_23, p_23;
    
    // Level 1
    assign g_01[0] = g[0];
    assign p_01[0] = p[0];
    assign g_01[1] = g[1] | (p[1] & g[0]);
    assign p_01[1] = p[1] & p[0];
    
    assign g_23[0] = g[2];
    assign p_23[0] = p[2];
    assign g_23[1] = g[3] | (p[3] & g[2]);
    assign p_23[1] = p[3] & p[2];

    // Level 2
    wire g_03, p_03;
    assign g_03 = g_23[1] | (p_23[1] & g_01[1]);
    assign p_03 = p_23[1] & p_01[1];

    // Stage 3: Carry Generation
    wire [3:0] c;
    assign c[0] = g[0];
    assign c[1] = g_01[1];
    assign c[2] = g_23[0] | (p_23[0] & g_01[1]);
    assign c[3] = g_03;

    // Stage 4: Sum Generation
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ c[0];
    assign sum[2] = p[2] ^ c[1];
    assign sum[3] = p[3] ^ c[2];

    assign carry = c[3];
endmodule