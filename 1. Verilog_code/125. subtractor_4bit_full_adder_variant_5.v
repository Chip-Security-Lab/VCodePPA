module subtractor_4bit_parallel_prefix (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_complement;
    wire [3:0] p, g;
    wire [3:0] g_prop;
    wire [3:0] c;
    
    // Generate and propagate signals
    assign b_complement = ~b;
    assign p = a ^ b_complement;
    assign g = a & b_complement;
    
    // Optimized parallel prefix computation using Kogge-Stone structure
    wire [3:0] p_prop;
    assign p_prop[0] = p[0];
    assign p_prop[1] = p[1] & p[0];
    assign p_prop[2] = p[2] & p[1] & p[0];
    assign p_prop[3] = p[3] & p[2] & p[1] & p[0];
    
    // Optimized carry generation
    assign g_prop[0] = g[0];
    assign g_prop[1] = g[1] | (p[1] & g[0]);
    assign g_prop[2] = g[2] | (p[2] & g[1]) | (p_prop[2] & g[0]);
    assign g_prop[3] = g[3] | (p[3] & g[2]) | (p_prop[3] & g[0]);
    
    // Carry computation
    assign c[0] = 1'b1;
    assign c[1] = g_prop[0];
    assign c[2] = g_prop[1];
    assign c[3] = g_prop[2];
    assign borrow = g_prop[3];
    
    // Sum computation
    assign diff = p ^ c;
endmodule