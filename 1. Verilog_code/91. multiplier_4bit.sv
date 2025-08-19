module multiplier_4bit (
    input [3:0] a,  // 4-bit 输入
    input [3:0] b,  // 4-bit 输入
    output [7:0] product  // 8-bit 输出
);
    assign product = a * b;  // 使用Verilog的乘法运算符
endmodule
