module rgb2yuv (
    input [7:0] r, g, b,
    output [7:0] y, u, v
);
assign y = (66*r + 129*g + 25*b + 128) >> 8;
assign u = (-38*r -74*g + 112*b + 128) >> 8;
assign v = (112*r -94*g -18*b + 128) >> 8;
endmodule
