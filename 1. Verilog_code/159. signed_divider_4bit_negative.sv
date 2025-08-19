module signed_divider_4bit_negative (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule
