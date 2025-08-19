module NAND_basic(
    input a, b,
    output y
);
    assign y = ~(a & b);  // 标准两输入NAND
endmodule
