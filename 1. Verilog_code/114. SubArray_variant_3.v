module BitSubtractor(
    input a,
    input b,
    output d
);
    assign d = a - b;
endmodule

module SubArray(
    input [3:0] a,
    input [3:0] b,
    output [3:0] d
);
    wire [3:0] g, p;
    wire [4:0] c;
    
    // Generate and propagate signals
    assign g = a & b;
    assign p = a ^ b;
    
    // Optimized carry lookahead logic
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & g[0]);
    assign c[3] = g[2] | (p[2] & (g[1] | (p[1] & g[0])));
    assign c[4] = g[3] | (p[3] & (g[2] | (p[2] & (g[1] | (p[1] & g[0])))));
    
    // Sum calculation
    assign d = p ^ c[3:0];
endmodule