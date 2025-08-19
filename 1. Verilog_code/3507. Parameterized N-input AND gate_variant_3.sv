//SystemVerilog
// Top-level module - Parallel Prefix Subtractor (8-bit)
module and_gate_n #(
    parameter N = 4  // Parameter kept for compatibility, but implementation is 8-bit specific
) (
    input wire [N-1:0] a,  // N-bit input A (minuend)
    input wire [N-1:0] b,  // N-bit input B (subtrahend)
    output wire [N-1:0] y  // N-bit output Y (difference)
);
    // For 8-bit operation (regardless of parameter N)
    wire [7:0] actual_a = {{(8-N){1'b0}}, a};
    wire [7:0] actual_b = {{(8-N){1'b0}}, b};
    wire [7:0] result;
    
    // Instantiate the 8-bit parallel prefix subtractor
    parallel_prefix_subtractor_8bit subtractor (
        .a(actual_a),
        .b(actual_b),
        .diff(result)
    );
    
    // Return the appropriate bits based on parameter N
    assign y = result[N-1:0];
endmodule

// 8-bit Parallel Prefix Subtractor - Optimized version
module parallel_prefix_subtractor_8bit (
    input wire [7:0] a,      // Minuend
    input wire [7:0] b,      // Subtrahend
    output wire [7:0] diff   // Difference
);
    wire [7:0] p;            // Propagate signals
    wire [7:0] g;            // Generate signals
    wire [7:0] c;            // Carry signals
    
    // Initial propagate and generate signals - optimized boolean expressions
    // Using a ^ ~b = a ^ b + 1'b1 (XOR with complement is equivalent to XNOR)
    assign p = a ~^ b;
    // Using a & ~b = a & ~b (unchanged but optimized in context)
    assign g = a & ~b;
    
    // Parallel prefix network for carry computation
    // Level 1 - Optimized black cell network
    wire [7:0] p_lvl1, g_lvl1;
    
    assign p_lvl1[0] = p[0];
    assign g_lvl1[0] = g[0];
    
    // Black cell optimization using direct boolean expressions
    assign p_lvl1[1] = p[1] & p[0];
    assign g_lvl1[1] = g[1] | (p[1] & g[0]);
    
    assign p_lvl1[2] = p[2];
    assign g_lvl1[2] = g[2];
    
    assign p_lvl1[3] = p[3] & p[2];
    assign g_lvl1[3] = g[3] | (p[3] & g[2]);
    
    assign p_lvl1[4] = p[4];
    assign g_lvl1[4] = g[4];
    
    assign p_lvl1[5] = p[5] & p[4];
    assign g_lvl1[5] = g[5] | (p[5] & g[4]);
    
    assign p_lvl1[6] = p[6];
    assign g_lvl1[6] = g[6];
    
    assign p_lvl1[7] = p[7] & p[6];
    assign g_lvl1[7] = g[7] | (p[7] & g[6]);
    
    // Level 2 - Optimized expressions
    wire [7:0] p_lvl2, g_lvl2;
    
    assign p_lvl2[0] = p_lvl1[0];
    assign g_lvl2[0] = g_lvl1[0];
    
    assign p_lvl2[1] = p_lvl1[1];
    assign g_lvl2[1] = g_lvl1[1];
    
    assign p_lvl2[2] = p_lvl1[2] & p_lvl1[0];
    assign g_lvl2[2] = g_lvl1[2] | (p_lvl1[2] & g_lvl1[0]);
    
    assign p_lvl2[3] = p_lvl1[3] & p_lvl1[1];
    assign g_lvl2[3] = g_lvl1[3] | (p_lvl1[3] & g_lvl1[1]);
    
    assign p_lvl2[4] = p_lvl1[4];
    assign g_lvl2[4] = g_lvl1[4];
    
    assign p_lvl2[5] = p_lvl1[5];
    assign g_lvl2[5] = g_lvl1[5];
    
    assign p_lvl2[6] = p_lvl1[6] & p_lvl1[4];
    assign g_lvl2[6] = g_lvl1[6] | (p_lvl1[6] & g_lvl1[4]);
    
    assign p_lvl2[7] = p_lvl1[7] & p_lvl1[5];
    assign g_lvl2[7] = g_lvl1[7] | (p_lvl1[7] & g_lvl1[5]);
    
    // Level 3 - Optimized boolean expressions
    wire [7:0] p_lvl3, g_lvl3;
    
    assign p_lvl3[0] = p_lvl2[0];
    assign g_lvl3[0] = g_lvl2[0];
    
    assign p_lvl3[1] = p_lvl2[1];
    assign g_lvl3[1] = g_lvl2[1];
    
    assign p_lvl3[2] = p_lvl2[2];
    assign g_lvl3[2] = g_lvl2[2];
    
    assign p_lvl3[3] = p_lvl2[3];
    assign g_lvl3[3] = g_lvl2[3];
    
    assign p_lvl3[4] = p_lvl2[4] & p_lvl2[0];
    assign g_lvl3[4] = g_lvl2[4] | (p_lvl2[4] & g_lvl2[0]);
    
    assign p_lvl3[5] = p_lvl2[5] & p_lvl2[1];
    assign g_lvl3[5] = g_lvl2[5] | (p_lvl2[5] & g_lvl2[1]);
    
    assign p_lvl3[6] = p_lvl2[6] & p_lvl2[2];
    assign g_lvl3[6] = g_lvl2[6] | (p_lvl2[6] & g_lvl2[2]);
    
    assign p_lvl3[7] = p_lvl2[7] & p_lvl2[3];
    assign g_lvl3[7] = g_lvl2[7] | (p_lvl2[7] & g_lvl2[3]);
    
    // Carry computation with initial carry-in of 1 for subtraction
    // Optimized carry chain using merged boolean expressions
    assign c[0] = 1'b1;  // Initial carry-in for subtraction
    
    // Carry chain optimization using direct assignments
    assign c[1] = g_lvl3[0] | p_lvl3[0]; // Since c[0]=1, p_lvl3[0] & 1 = p_lvl3[0]
    assign c[2] = g_lvl3[1] | (p_lvl3[1] & c[1]);
    assign c[3] = g_lvl3[2] | (p_lvl3[2] & c[2]);
    assign c[4] = g_lvl3[3] | (p_lvl3[3] & c[3]);
    assign c[5] = g_lvl3[4] | (p_lvl3[4] & c[4]);
    assign c[6] = g_lvl3[5] | (p_lvl3[5] & c[5]);
    assign c[7] = g_lvl3[6] | (p_lvl3[6] & c[6]);
    
    // Final sum/difference computation using optimized XOR chain
    // p ^ {c[6:0], 1'b1} is equivalent to p ~^ {c[6:0], 1'b0} due to boolean identity
    assign diff = p ~^ {c[6:0], 1'b0};
endmodule