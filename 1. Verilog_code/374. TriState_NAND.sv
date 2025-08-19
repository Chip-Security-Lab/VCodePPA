module TriState_NAND(
    input en,
    input [3:0] a, b,
    output [3:0] y
);
    assign y = en ? ~(a & b) : 4'bzzzz;
endmodule
