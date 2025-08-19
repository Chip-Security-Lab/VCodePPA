module Hier_NAND(
    input [1:0] a, b,
    output [3:0] y
);
    NAND_basic bit0(.a(a[0]), .b(b[0]), .y(y[0]));
    NAND_basic bit1(.a(a[1]), .b(b[1]), .y(y[1]));
    assign y[3:2] = 2'b11;  // Fixed high bits
endmodule

module NAND_basic(
    input a, b,
    output y
);
    assign y = ~(a & b);
endmodule