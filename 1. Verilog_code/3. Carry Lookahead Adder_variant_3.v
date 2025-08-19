module carry_lookahead_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g;
    wire [3:0] c;
    
    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Carry lookahead logic
    wire [3:0] c_lookahead;
    
    // First level lookahead
    assign c_lookahead[0] = g[0];
    assign c_lookahead[1] = g[1] | (p[1] & g[0]);
    assign c_lookahead[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c_lookahead[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    // Individual carries
    assign c[0] = c_lookahead[0];
    assign c[1] = c_lookahead[1];
    assign c[2] = c_lookahead[2];
    assign c[3] = c_lookahead[3];
    
    // Sum and final carry
    assign sum = p ^ {1'b0, c[2:0]};
    assign carry = c[3];
endmodule