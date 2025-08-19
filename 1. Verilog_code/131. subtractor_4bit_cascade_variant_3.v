module subtractor_4bit_parallel (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);

    // Generate and Propagate signals
    wire [3:0] g, p;
    assign g = a & ~b;  // Generate
    assign p = a ^ ~b;  // Propagate

    // Optimized parallel prefix computation
    wire [3:0] g_level1, p_level1;
    wire [3:0] g_level2, p_level2;
    wire [3:0] g_level3, p_level3;

    // Level 1 - Optimized with fewer gates
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[2] = p[2] & p[1];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];

    // Level 2 - Optimized with fewer gates
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];

    // Level 3 - Optimized with fewer gates
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3] | (p_level2[3] & g_level2[0]);
    assign p_level3[3] = p_level2[3] & p_level2[0];

    // Final difference and borrow computation - Optimized
    assign diff[0] = p[0];
    assign diff[1] = p[1] ^ g_level3[0];
    assign diff[2] = p[2] ^ g_level3[1];
    assign diff[3] = p[3] ^ g_level3[2];
    assign borrow = g_level3[3];

endmodule