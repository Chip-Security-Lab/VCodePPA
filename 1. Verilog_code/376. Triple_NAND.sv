module Triple_NAND(
    input a, b, c,
    output y
);
    assign y = ~(a & b & c);  // 三输入扩展
endmodule

