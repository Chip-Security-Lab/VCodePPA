module ShiftCompare_XNOR(
    input [2:0] shift,
    input [7:0] base,
    output [7:0] res
);
    assign res = ~((base << shift) ^ base);
endmodule
