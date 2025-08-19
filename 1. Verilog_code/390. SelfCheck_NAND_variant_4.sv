//SystemVerilog
module SelfCheck_NAND(
    input a, b,
    output y,
    output parity
);
    // 直接使用NAND逻辑门实现
    assign y = ~(a & b);
    // 奇偶校验位应该是输入和输出的异或，而不是简单地等于输出
    assign parity = a ^ b ^ y;
endmodule