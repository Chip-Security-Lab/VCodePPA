module divider_8bit_with_overflow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);
    assign quotient = (b == 0) ? 8'b00000000 : a / b;
    assign remainder = (b == 0) ? 8'b00000000 : a % b;
    assign overflow = (b == 0);  // 除数为零时，发生溢出
endmodule
