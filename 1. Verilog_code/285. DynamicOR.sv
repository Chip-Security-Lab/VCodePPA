module DynamicOR(
    input [2:0] shift,
    input [31:0] vec1, vec2,
    output [31:0] res
);
    assign res = (vec1 << shift) | vec2;
endmodule
