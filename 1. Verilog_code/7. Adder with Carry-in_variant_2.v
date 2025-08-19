module adder_with_carry (
    input  [4:0] a, b,
    input        cin,
    output [4:0] sum,
    output       carry
);

    wire [4:0] g, p;
    wire [5:0] c;
    wire [1:0] block_g, block_p;
    wire [2:0] block_c;
    
    // Generate and propagate signals
    assign g = a & b;
    assign p = a ^ b;
    
    // Block generate and propagate
    assign block_g[0] = g[1] | (p[1] & g[0]);
    assign block_p[0] = p[1] & p[0];
    assign block_g[1] = g[3] | (p[3] & g[2]);
    assign block_p[1] = p[3] & p[2];
    
    // Block carry lookahead
    assign block_c[0] = cin;
    assign block_c[1] = block_g[0] | (block_p[0] & block_c[0]);
    assign block_c[2] = block_g[1] | (block_p[1] & block_g[0]) | (block_p[1] & block_p[0] & block_c[0]);
    
    // Individual carry calculation
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & block_c[1]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & block_c[1]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & block_c[1]);
    
    // Sum calculation
    assign sum = p ^ c[4:0];
    assign carry = c[5];

endmodule