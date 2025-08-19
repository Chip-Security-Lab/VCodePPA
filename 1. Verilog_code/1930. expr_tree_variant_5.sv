//SystemVerilog
// Top-level module: Hierarchical expression tree
module expr_tree #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    input  [1:0]    op,
    output reg [DW-1:0] out
);

    // Internal wires for submodule outputs
    wire [DW-1:0] sum_mul_result;
    wire [DW-1:0] sub_shift_result;
    wire [DW-1:0] cmp_mux_result;
    wire [DW-1:0] xor_result;

    // Submodule: Performs a + (b * c)
    sum_mul #(.DW(DW)) u_sum_mul (
        .a(a),
        .b(b),
        .c(c),
        .result(sum_mul_result)
    );

    // Submodule: Performs (a - b) << c
    sub_shift #(.DW(DW)) u_sub_shift (
        .a(a),
        .b(b),
        .c(c),
        .result(sub_shift_result)
    );

    // Submodule: Conditional select (a > b ? c : a)
    cmp_mux #(.DW(DW)) u_cmp_mux (
        .a(a),
        .b(b),
        .c(c),
        .result(cmp_mux_result)
    );

    // Submodule: a ^ b ^ c
    xor3 #(.DW(DW)) u_xor3 (
        .a(a),
        .b(b),
        .c(c),
        .result(xor_result)
    );

    // Output selection logic
    always @* begin
        case(op)
            2'b00: out = sum_mul_result;
            2'b01: out = sub_shift_result;
            2'b10: out = cmp_mux_result;
            default: out = xor_result;
        endcase
    end

endmodule

// Submodule: Adds a to the product of b and c
module sum_mul #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    assign result = a + (b * c);
endmodule

// Submodule: Computes (a - b) shifted left by c
module sub_shift #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    assign result = (a - b) << c;
endmodule

// Submodule: If a > b, output c; else output a
module cmp_mux #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    reg [DW-1:0] result_reg;
    always @* begin
        if (a > b)
            result_reg = c;
        else
            result_reg = a;
    end
    assign result = result_reg;
endmodule

// Submodule: Computes bitwise XOR of a, b, and c
module xor3 #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input  [DW-1:0] c,
    output [DW-1:0] result
);
    assign result = a ^ b ^ c;
endmodule