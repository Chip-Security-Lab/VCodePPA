module SubArray(input [3:0] a, b, output [3:0] d);
    // Kogge-Stone adder implementation for 4-bit subtraction
    // First, invert b to perform subtraction (a - b = a + (-b))
    wire [3:0] b_inv = ~b;
    
    // Generate and propagate signals
    wire [3:0] g, p;
    genvar i;
    generate
        for(i=0; i<4; i=i+1) begin
            assign g[i] = a[i] & b_inv[i];
            assign p[i] = a[i] ^ b_inv[i];
        end
    endgenerate
    
    // Kogge-Stone prefix computation
    wire [3:0] g_level1, p_level1;
    wire [3:0] g_level2, p_level2;
    
    // Level 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[2] = p[2] & p[1];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];
    
    // Level 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    
    // Final carry computation
    wire [3:0] carry;
    assign carry[0] = g_level2[0];
    assign carry[1] = g_level2[1];
    assign carry[2] = g_level2[2];
    assign carry[3] = g_level2[3];
    
    // Sum computation
    assign d[0] = p[0] ^ 1'b0;
    assign d[1] = p[1] ^ carry[0];
    assign d[2] = p[2] ^ carry[1];
    assign d[3] = p[3] ^ carry[2];
endmodule