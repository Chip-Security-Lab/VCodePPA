module add_signed_divide (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] sum,
    output signed [7:0] quotient
);
    assign sum = a + c;                // 加法
    assign quotient = a / b;            // 除法
endmodule
