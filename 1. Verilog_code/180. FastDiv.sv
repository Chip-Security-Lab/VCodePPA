module FastDiv(
    input [15:0] a,b,
    output [15:0] q
);
    wire [31:0] inv_b = 32'hFFFF_FFFF / b;
    assign q = (inv_b * a) >> 16;
endmodule