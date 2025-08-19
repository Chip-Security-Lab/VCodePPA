module SelfCheck_NAND(
    input a, b,
    output y,
    output parity
);
    assign y = ~(a & b);
    assign parity = ^y;  // 奇偶校验位
endmodule
