module simple_4bit_divider (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule
