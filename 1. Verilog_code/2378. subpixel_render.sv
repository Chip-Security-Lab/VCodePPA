module subpixel_render (
    input [7:0] px1, px2,
    output [7:0] px_out
);
assign px_out = (px1 * 3 + px2 * 1) >> 2;
endmodule
