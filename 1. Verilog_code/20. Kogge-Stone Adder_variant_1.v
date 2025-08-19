module kogge_stone_adder(
    input [3:0] a,b,
    output [3:0] sum
);
    wire [3:0] p, g;
    wire [3:0] c;
    
    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Level 1: Generate group propagate and generate signals
    wire [3:0] p_l1, g_l1;
    
    assign g_l1[0] = g[0];
    assign p_l1[0] = p[0];
    
    assign g_l1[1] = g[1] | (p[1] & g[0]);
    assign p_l1[1] = p[1] & p[0];
    
    assign g_l1[2] = g[2] | (p[2] & g[1]);
    assign p_l1[2] = p[2] & p[1];
    
    assign g_l1[3] = g[3] | (p[3] & g[2]);
    assign p_l1[3] = p[3] & p[2];
    
    // Level 2: Generate group propagate and generate signals
    wire [3:0] p_l2, g_l2;
    
    assign g_l2[0] = g_l1[0];
    assign p_l2[0] = p_l1[0];
    
    assign g_l2[1] = g_l1[1];
    assign p_l2[1] = p_l1[1];
    
    assign g_l2[2] = g_l1[2] | (p_l1[2] & g_l1[0]);
    assign p_l2[2] = p_l1[2] & p_l1[0];
    
    assign g_l2[3] = g_l1[3] | (p_l1[3] & g_l1[1]);
    assign p_l2[3] = p_l1[3] & p_l1[1];
    
    // Calculate carries
    assign c[0] = 1'b0;
    assign c[1] = g_l2[0];
    assign c[2] = g_l2[1];
    assign c[3] = g_l2[2] | (p_l2[2] & g_l2[0]);
    
    // Calculate sum
    assign sum = p ^ c;
endmodule