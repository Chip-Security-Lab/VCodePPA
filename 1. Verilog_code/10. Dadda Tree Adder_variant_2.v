// Top level module
module dadda_adder (
    input  [3:0] a, b,
    output [3:0] sum
);
    wire [3:0] g, p;
    wire [3:0] c;

    // Instance of generate_propagate module
    generate_propagate gp_inst (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // Instance of carry_lookahead module  
    carry_lookahead cl_inst (
        .g(g),
        .p(p),
        .c(c)
    );

    // Instance of sum_calculation module
    sum_calculation sc_inst (
        .p(p),
        .c(c),
        .sum(sum)
    );

endmodule

// Generate and propagate signals module
module generate_propagate (
    input  [3:0] a, b,
    output [3:0] g, p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

// Carry lookahead logic module
module carry_lookahead (
    input  [3:0] g, p,
    output [3:0] c
);
    assign c[0] = g[0] | (p[0] & 1'b0);
    assign c[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & 1'b0);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & 1'b0);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & 1'b0);
endmodule

// Sum calculation module
module sum_calculation (
    input  [3:0] p, c,
    output [3:0] sum
);
    assign sum[0] = p[0] ^ 1'b0;
    assign sum[1] = p[1] ^ c[0];
    assign sum[2] = p[2] ^ c[1];
    assign sum[3] = p[3] ^ c[2];
endmodule