module shift_compare (
    input [4:0] x,
    input [4:0] y,
    output [4:0] shift_left,
    output [4:0] shift_right,
    output equal
);
    assign shift_left = x << 1;
    assign shift_right = y >> 1;
    assign equal = (x == y);
endmodule
