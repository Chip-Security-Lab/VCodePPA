module kogge_stone_adder(
    input [3:0] a,b,
    output [3:0] sum
);
    wire [3:0] p = a ^ b;
    wire [3:0] g = a & b;
    
    // Prefix tree
    wire [3:0] c;
    
    // Generate carries more efficiently
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & g[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    // Sum computation
    assign sum[0] = p[0] ^ 1'b0;
    assign sum[3:1] = p[3:1] ^ c[2:0];
endmodule