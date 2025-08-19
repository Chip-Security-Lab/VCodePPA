module subtractor_4bit (
    input [3:0] a,  // 4-bit 输入
    input [3:0] b,  // 4-bit 输入
    output [3:0] diff  // 4-bit 输出
);
    assign diff = a - b;  // 直接使用 Verilog 内建的减法运算符
endmodule
