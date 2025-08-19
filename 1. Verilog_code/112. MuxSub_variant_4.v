module MuxSub(input [3:0] x, y, output [3:0] d);
    // Internal signals for parallel prefix adder
    wire [3:0] y_neg;      // Negated y (one's complement)
    wire [3:0] sum;        // Sum bits
    wire [3:0] g;          // Generate signals
    wire [3:0] p;          // Propagate signals
    wire [3:0] g_level1;   // Level 1 generate
    wire [3:0] p_level1;   // Level 1 propagate
    wire [3:0] g_level2;   // Level 2 generate
    wire [3:0] p_level2;   // Level 2 propagate
    wire [3:0] carry;      // Final carry bits
    
    // Negate y (one's complement)
    assign y_neg = ~y;
    
    // Initial generate and propagate signals
    assign g = x & y_neg;
    assign p = x ^ y_neg;
    
    // Level 1 prefix computation
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[2] = p[2] & p[1];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];
    
    // Level 2 prefix computation
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    
    // Final carry computation
    assign carry[0] = 1'b1;
    assign carry[1] = g_level2[0] | (p_level2[0] & carry[0]);
    assign carry[2] = g_level2[1] | (p_level2[1] & carry[0]);
    assign carry[3] = g_level2[2] | (p_level2[2] & carry[0]);
    
    // Sum computation
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
    
    // Output assignment
    assign d = sum;
endmodule