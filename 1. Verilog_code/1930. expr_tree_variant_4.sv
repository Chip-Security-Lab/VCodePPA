//SystemVerilog
// Top-level module: Hierarchical Expression Tree

module expr_tree #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    input  [1:0]    op,
    output [DW-1:0] out
);

    // Internal signals for function group outputs
    wire [DW-1:0] arithmetic_result;
    wire [DW-1:0] logic_result;

    // Arithmetic Operations Submodule: handles add-mul, sub-shift
    arithmetic_unit #(.DW(DW)) u_arithmetic (
        .a(a),
        .b(b),
        .c(c),
        .op(op),
        .result(arithmetic_result)
    );

    // Logic Operations Submodule: handles cmp-mux, xor
    logic_unit #(.DW(DW)) u_logic (
        .a(a),
        .b(b),
        .c(c),
        .op(op),
        .result(logic_result)
    );

    // Output selection logic between arithmetic and logic results
    assign out = (op == 2'b00 || op == 2'b01) ? arithmetic_result : logic_result;

endmodule

// ---------------------------------------------------------------------------
// Arithmetic Operations Unit
// Handles addition-multiplication and subtraction-shift operations
module arithmetic_unit #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    input  [1:0]    op,
    output [DW-1:0] result
);
    wire [DW-1:0] add_mul_result;
    wire [DW-1:0] sub_shift_result;

    // Addition & Multiplication Submodule
    add_mul_unit #(.DW(DW)) u_add_mul (
        .a(a),
        .b(b),
        .c(c),
        .result(add_mul_result)
    );

    // Subtraction & Shift Submodule
    sub_shift_unit #(.DW(DW)) u_sub_shift (
        .a(a),
        .b(b),
        .c(c),
        .result(sub_shift_result)
    );

    // Arithmetic result selection based on op
    assign result = (op == 2'b00) ? add_mul_result : sub_shift_result;

endmodule

// ---------------------------------------------------------------------------
// Logic Operations Unit
// Handles comparison-mux and xor operations
module logic_unit #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    input  [1:0]    op,
    output [DW-1:0] result
);
    wire [DW-1:0] cmp_mux_result;
    wire [DW-1:0] xor_result;

    // Comparison & Multiplexer Submodule
    cmp_mux_unit #(.DW(DW)) u_cmp_mux (
        .a(a),
        .b(b),
        .c(c),
        .result(cmp_mux_result)
    );

    // XOR Submodule
    xor_unit #(.DW(DW)) u_xor (
        .a(a),
        .b(b),
        .c(c),
        .result(xor_result)
    );

    // Logic result selection based on op
    assign result = (op == 2'b10) ? cmp_mux_result : xor_result;

endmodule

// ---------------------------------------------------------------------------
// Addition and Multiplication Unit
// Computes: a + (b * c)
module add_mul_unit #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    wire [DW-1:0] mul_result;
    assign mul_result = b * c;
    assign result = a + mul_result;
endmodule

// ---------------------------------------------------------------------------
// Subtraction and Shift Unit
// Computes: (a - b) << c
module sub_shift_unit #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    wire [DW-1:0] sub_result;
    assign sub_result = a - b;
    assign result = sub_result << c;
endmodule

// ---------------------------------------------------------------------------
// Comparison and Multiplexer Unit
// Computes: a > b ? c : a
module cmp_mux_unit #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    assign result = (a > b) ? c : a;
endmodule

// ---------------------------------------------------------------------------
// XOR Unit
// Computes: a ^ b ^ c
module xor_unit #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    assign result = a ^ b ^ c;
endmodule