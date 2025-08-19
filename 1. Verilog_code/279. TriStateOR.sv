module TriStateOR(
    input oe,       // 输出使能
    input [7:0] a, b,
    output [7:0] y
);
    assign y = oe ? (a | b) : 8'bzzzzzzzz;
endmodule
