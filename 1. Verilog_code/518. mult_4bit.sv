module mult_4bit(
    input [3:0] a, b,
    output [7:0] prod
);
    assign prod = a * b;  // 算术运算符实现
endmodule