// Top level module
module dadda_adder (
    input  [3:0] a, b,
    output [3:0] sum
);

    wire [3:0] g, p;
    wire [3:0] c;
    wire [3:0] c_reg;

    // Instantiate generate/propagate module
    gp_generator gp_gen (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // Instantiate carry computation module
    carry_computer carry_comp (
        .g(g),
        .p(p),
        .c(c)
    );

    // Instantiate sum computation module
    sum_computer sum_comp (
        .p(p),
        .c(c),
        .sum(sum)
    );

endmodule

// Generate and propagate signals module
module gp_generator (
    input  [3:0] a, b,
    output [3:0] g, p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

// Carry computation module
module carry_computer (
    input  [3:0] g, p,
    output [3:0] c
);
    wire [2:0] carry_terms;
    
    assign carry_terms[0] = g[0];
    assign carry_terms[1] = p[1] & g[0];
    assign carry_terms[2] = p[2] & p[1] & g[0];

    assign c[0] = g[0];
    assign c[1] = g[1] | carry_terms[1];
    assign c[2] = g[2] | (p[2] & g[1]) | carry_terms[2];
    assign c[3] = g[3] | (p[3] & g[2]) | 
                 (p[3] & p[2] & g[1]) | 
                 (p[3] & p[2] & p[1] & g[0]);
endmodule

// Sum computation module
module sum_computer (
    input  [3:0] p, c,
    output [3:0] sum
);
    assign sum = p ^ {c[2:0], 1'b0};
endmodule