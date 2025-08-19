//SystemVerilog
// Top-level module: nor3_bitwise_hier
// This module implements a 3-input bitwise NOR using hierarchical submodules with simplified Boolean expressions.

module nor3_bitwise_hier (
    input wire [2:0] A,  // 3-bit input
    output wire Y        // Output: NOR of inputs
);
    // Directly instantiate the simplified nor3_bitwise submodule
    nor3_bitwise u_nor3 (
        .in1(A[0]),
        .in2(A[1]),
        .in3(A[2]),
        .nor_out(Y)
    );
endmodule

// Submodule: nor3_bitwise
// Description: 3-input NOR gate with simplified Boolean expression.
// NOR(A, B, C) = ~(A | B | C) = (~A) & (~B) & (~C)
module nor3_bitwise (
    input wire in1,
    input wire in2,
    input wire in3,
    output wire nor_out
);
    assign nor_out = (~in1) & (~in2) & (~in3);
endmodule