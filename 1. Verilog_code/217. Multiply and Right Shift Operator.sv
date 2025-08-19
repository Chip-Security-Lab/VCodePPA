module signed_add_divide (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] sum,
    output signed [7:0] quotient
);
    assign sum = a + b;              // 加法
    assign quotient = a / b;         // 除法
endmodule
