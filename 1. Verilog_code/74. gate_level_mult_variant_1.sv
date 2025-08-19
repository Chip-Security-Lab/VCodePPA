//SystemVerilog
// Top level module
module gate_level_mult (
    input [1:0] a, b,
    output [3:0] p
);

    // Partial product generation module
    wire [3:0] pp;
    partial_product_gen pp_gen (
        .a(a),
        .b(b),
        .pp(pp)
    );

    // Final product assignment
    assign p = pp;

endmodule

// Partial product generation module
module partial_product_gen (
    input [1:0] a, b,
    output [3:0] pp
);

    // Generate partial products using optimized logic
    wire a0b0 = a[0] & b[0];
    wire a1b0 = a[1] & b[0];
    wire a0b1 = a[0] & b[1];
    wire a1b1 = a[1] & b[1];

    assign pp[0] = a0b0;
    assign pp[1] = a1b0 ^ a0b1;
    assign pp[2] = a1b1 ^ (a1b0 & a0b1);
    assign pp[3] = a1b1 & (a1b0 & a0b1);

endmodule