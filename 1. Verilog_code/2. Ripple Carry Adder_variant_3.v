module carry_lookahead_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g;
    wire [4:0] c;
    
    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Carry lookahead logic
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum calculation
    assign sum = p ^ c[3:0];
    assign carry = c[4];
endmodule