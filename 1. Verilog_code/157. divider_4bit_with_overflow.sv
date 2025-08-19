module divider_4bit_with_overflow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder,
    output overflow  // 溢出检测
);
    assign quotient = (b == 0) ? 4'b0000 : a / b;
    assign remainder = (b == 0) ? 4'b0000 : a % b;
    assign overflow = (b == 0);  // 除数为零时，发生溢出
endmodule
