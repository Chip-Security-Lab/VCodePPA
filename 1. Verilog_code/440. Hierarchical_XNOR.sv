module Hierarchical_XNOR(
    input [1:0] a, b,
    output [3:0] result
);
    XNOR_Basic bit0(.a(a[0]), .b(b[0]), .y(result[0]));
    XNOR_Basic bit1(.a(a[1]), .b(b[1]), .y(result[1]));
    assign result[3:2] = 2'b11; // Fixed high bits
endmodule

module XNOR_Basic(
    input a, b,
    output y
);
    assign y = ~(a ^ b);
endmodule