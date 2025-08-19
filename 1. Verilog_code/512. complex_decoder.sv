module complex_decoder(
    input a, b, c,
    output [7:0] dec
);
    assign dec[0] = ~a & ~b & ~c;
    assign dec[1] = ~a & ~b & c;
    assign dec[2] = ~a & b & ~c;
    assign dec[3] = ~a & b & c;
    assign dec[4] = a & ~b & ~c;
    assign dec[5] = a & ~b & c;
    assign dec[6] = a & b & ~c;
    assign dec[7] = a & b & c;
endmodule