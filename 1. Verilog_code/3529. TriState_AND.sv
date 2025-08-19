module TriState_AND(
    input oe_n, // 低有效使能
    input [3:0] x, y,
    output [3:0] z
);
    assign z = (~oe_n) ? (x & y) : 4'bzzzz;
endmodule
