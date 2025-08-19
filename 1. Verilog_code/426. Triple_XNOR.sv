module Triple_XNOR(
    input a, b, c, d,
    output y
);
    assign y = ~(a ^ b ^ c ^ d); // 四输入奇偶检测
endmodule
