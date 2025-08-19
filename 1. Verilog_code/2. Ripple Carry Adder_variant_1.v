module carry_lookahead_unit(
    input [4:0] p,
    input [4:0] g,
    input cin,
    output [4:0] c
);
    // Generate carry signals using lookahead logic
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
endmodule

module carry_lookahead_adder(
    input [4:0] a, b,
    input cin,
    output [4:0] sum,
    output cout
);
    wire [4:0] p, g, c;
    
    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Instantiate carry lookahead unit
    carry_lookahead_unit cla(
        .p(p),
        .g(g),
        .cin(cin),
        .c(c)
    );
    
    // Calculate sum
    assign sum = p ^ c;
    
    // Determine final carry out
    assign cout = c[4];
endmodule