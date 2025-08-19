module subtractor_signed_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff
);

    // Optimized carry lookahead adder for subtraction
    wire [3:0] b_comp = ~b + 1'b1;
    wire [3:0] p = a ^ b_comp;
    wire [3:0] g = a & b_comp;
    
    // Optimized carry generation
    wire [3:0] c;
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & (g[0] | (p[0] & c[0])));
    assign c[3] = g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & c[0])))));
    
    // Optimized sum calculation
    assign diff = p ^ {c[2:0], 1'b0};

endmodule