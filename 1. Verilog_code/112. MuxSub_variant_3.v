module MuxSub(input [3:0] x, y, output [3:0] d);
    // Optimized subtraction using carry-lookahead logic
    wire [3:0] y_neg = ~y + 1;
    
    // Generate and propagate signals with optimized expressions
    wire [3:0] g = x & y_neg;
    wire [3:0] p = x ^ y_neg;
    
    // Optimized carry computation
    wire [3:0] c;
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & g[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]);
    
    // Optimized sum computation
    assign d[0] = p[0];
    assign d[1] = p[1] ^ c[0];
    assign d[2] = p[2] ^ c[1];
    assign d[3] = p[3] ^ c[2];
endmodule