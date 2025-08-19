module multiply_divide_operator (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product,
    output [7:0] quotient,
    output [7:0] remainder
);
    assign product = a * b;  // 乘法
    assign quotient = a / b; // 除法
    assign remainder = a % b; // 余数
endmodule
