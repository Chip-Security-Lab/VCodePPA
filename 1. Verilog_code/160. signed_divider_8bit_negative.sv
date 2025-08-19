module signed_divider_8bit_negative (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient,
    output signed [7:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule


