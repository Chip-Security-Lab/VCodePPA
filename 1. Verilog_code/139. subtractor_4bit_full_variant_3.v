module subtractor_4bit_full (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);

    wire [3:0] b_complement;
    wire [4:0] sum;
    wire [4:0] g, p;
    wire [4:0] c;
    
    // Compute two's complement of b
    assign b_complement = ~b;
    
    // Brent-Kung adder implementation
    // Generate and propagate signals
    assign g[0] = a[0] & b_complement[0];
    assign p[0] = a[0] ^ b_complement[0];
    assign g[1] = a[1] & b_complement[1];
    assign p[1] = a[1] ^ b_complement[1];
    assign g[2] = a[2] & b_complement[2];
    assign p[2] = a[2] ^ b_complement[2];
    assign g[3] = a[3] & b_complement[3];
    assign p[3] = a[3] ^ b_complement[3];
    assign g[4] = 1'b0;
    assign p[4] = 1'b0;
    
    // Carry computation - optimized using Boolean algebra
    assign c[0] = 1'b1;  // Initial carry-in for subtraction
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum computation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = c[4];
    
    // Extract the difference and borrow
    assign diff = sum[3:0];
    assign borrow = ~sum[4];
endmodule