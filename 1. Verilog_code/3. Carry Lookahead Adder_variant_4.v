// Top level module
module carry_lookahead_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g;
    wire [3:0] c;
    wire [1:0] block_p, block_g;

    // Instantiate generate/propagate module
    gp_generator gp_gen (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );

    // Instantiate block level module
    block_level block_lvl (
        .p(p),
        .g(g),
        .block_p(block_p),
        .block_g(block_g)
    );

    // Instantiate carry computation module
    carry_compute carry_comp (
        .p(p),
        .g(g),
        .block_p(block_p),
        .block_g(block_g),
        .c(c)
    );

    // Instantiate sum generation module
    sum_generator sum_gen (
        .p(p),
        .c(c),
        .sum(sum)
    );

    assign carry = c[3];

endmodule

// Generate and propagate signals module
module gp_generator (
    input  [3:0] a, b,
    output [3:0] p, g
);
    assign p = a ^ b;
    assign g = a & b;
endmodule

// Block level generate and propagate module
module block_level (
    input  [3:0] p, g,
    output [1:0] block_p, block_g
);
    assign block_g[0] = g[1] | (p[1] & g[0]);
    assign block_p[0] = p[1] & p[0];
    assign block_g[1] = g[3] | (p[3] & g[2]);
    assign block_p[1] = p[3] & p[2];
endmodule

// Carry computation module
module carry_compute (
    input  [3:0] p, g,
    input  [1:0] block_p, block_g,
    output [3:0] c
);
    assign c[0] = g[0];
    assign c[1] = block_g[0];
    assign c[2] = g[2] | (p[2] & block_g[0]);
    assign c[3] = block_g[1] | (block_p[1] & block_g[0]);
endmodule

// Sum generation module
module sum_generator (
    input  [3:0] p, c,
    output [3:0] sum
);
    assign sum = p ^ c;
endmodule