module CarryDiv(
    input [3:0] D, d,
    output [3:0] q
);
    wire [3:0] p = D - d;
    assign q = {3'b0, p[3]} + (p[3] ? 0 : 1);
endmodule