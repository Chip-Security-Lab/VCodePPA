module signed_divider_16bit (
    input signed [15:0] a,
    input signed [15:0] b,
    output signed [15:0] quotient,
    output signed [15:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule
