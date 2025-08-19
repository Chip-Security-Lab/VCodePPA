// Top-level module
module subtractor_overflow_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output overflow
);
    // Generate and propagate signals
    wire [3:0] g = a & ~b;
    wire [3:0] p = a ^ ~b;
    
    // Carry lookahead logic
    wire c0 = 1'b1; // Initial borrow
    wire c1 = g[0] | (p[0] & c0);
    wire c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c0);
    wire c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c0);
    wire c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c0);
    
    // Final difference calculation
    assign diff = p ^ {c3, c2, c1, c0};
    
    // Overflow detection
    assign overflow = (a[3] & ~b[3] & ~diff[3]) | (~a[3] & b[3] & diff[3]);
endmodule