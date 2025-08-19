module subtractor_4bit_full (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_complement;
    wire [4:0] sum;
    wire [3:0] g, p;
    wire [4:0] c;
    
    assign b_complement = ~b;
    
    // Generate and Propagate signals
    assign g = a & b_complement;
    assign p = a ^ b_complement;
    
    // Carry chain
    assign c[0] = 1'b1;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum calculation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = c[4];
    
    assign diff = sum[3:0];
    assign borrow = ~sum[4];
endmodule