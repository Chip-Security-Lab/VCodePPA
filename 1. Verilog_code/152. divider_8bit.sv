module divider_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule
