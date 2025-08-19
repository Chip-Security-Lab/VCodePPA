//SystemVerilog
// Carry Look-ahead Generator Module
module carry_lookahead_gen(
    input [4:0] g, p,
    output [5:0] c
);
    // Generate carry signals using look-ahead logic
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & g[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]);
endmodule

// Sum Generator Module
module sum_gen(
    input [4:0] p,
    input [4:0] c,
    output [4:0] sum
);
    assign sum = p ^ c[4:0];
endmodule

// Top Level Adder Module
module func_adder(
    input [4:0] alpha, beta,
    output [5:0] sigma
);
    // Internal signals
    wire [4:0] g, p;
    wire [5:0] c;
    wire [4:0] sum;

    // Generate and propagate signals
    assign g = alpha & beta;
    assign p = alpha ^ beta;

    // Instantiate carry look-ahead generator
    carry_lookahead_gen cla_gen(
        .g(g),
        .p(p),
        .c(c)
    );

    // Instantiate sum generator
    sum_gen sum_gen_inst(
        .p(p),
        .c(c),
        .sum(sum)
    );

    // Final sum output
    assign sigma = {c[5], sum};

endmodule