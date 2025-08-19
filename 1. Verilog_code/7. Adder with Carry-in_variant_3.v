// Top level module
module adder_with_carry (
    input  [3:0] a, b,
    input        cin,
    output [3:0] sum,
    output       carry
);

    // Internal signals
    wire [3:0] g, p;
    wire [3:0] c;

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
        .cin(cin),
        .c(c)
    );

    // Instantiate sum computation module
    sum_computer sum_comp (
        .p(p),
        .c(c),
        .sum(sum)
    );

    // Final carry output
    assign carry = c[3];

endmodule

// Generate and propagate computation module
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
    input        cin,
    output [3:0] c
);
    wire [3:0] c1, c2;

    // First level
    assign c1[0] = cin;
    assign c1[1] = g[0] | (p[0] & cin);
    assign c1[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c1[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);

    // Second level
    assign c2[0] = c1[0];
    assign c2[1] = c1[1];
    assign c2[2] = c1[2];
    assign c2[3] = c1[3];

    // Final carry
    assign c = c2;
endmodule

// Sum computation module
module sum_computer (
    input  [3:0] p, c,
    output [3:0] sum
);
    assign sum = p ^ c;
endmodule