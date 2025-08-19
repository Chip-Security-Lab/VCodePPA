module Sub2(
    input [3:0] x,
    input [3:0] y,
    output [3:0] diff,
    output borrow
);
    wire [3:0] y_inv;
    wire [3:0] g;
    wire [3:0] p;
    wire [3:0] c;
    
    // Generate and propagate signals
    assign y_inv = ~y;
    assign g = x & y_inv;
    assign p = x ^ y_inv;
    
    // Carry lookahead logic
    assign c[0] = 1'b1;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign borrow = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Difference calculation
    assign diff = p ^ c;
endmodule