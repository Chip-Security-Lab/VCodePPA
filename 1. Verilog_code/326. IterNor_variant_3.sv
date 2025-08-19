//SystemVerilog
// Top-level module: IterNor
module IterNor(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] y
);

    // Instantiate lower 4-bit NOR submodule
    Nor4 u_nor4_low (
        .a(a[3:0]),
        .b(b[3:0]),
        .y(y[3:0])
    );

    // Instantiate upper 4-bit NOR submodule
    Nor4 u_nor4_high (
        .a(a[7:4]),
        .b(b[7:4]),
        .y(y[7:4])
    );

endmodule

// 4-bit parallel NOR submodule
// Performs bitwise NOR operation on two 4-bit inputs
module Nor4(
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] y
);
    assign y = ~(a | b);
endmodule