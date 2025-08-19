module TriState_XNOR(
    input oe,
    input [3:0] in1, in2,
    output [3:0] res
);
    assign res = oe ? ~(in1 ^ in2) : 4'bzzzz;
endmodule
