module divider_16bit_unsigned (
    input [15:0] a,
    input [15:0] b,
    output [15:0] quotient,
    output [15:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule
