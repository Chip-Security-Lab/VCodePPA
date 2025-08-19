module nor2_basic (
    input wire A, B,
    output wire Y
);
    assign Y = ~(A | B);  // 输出为 A 和 B 的或运算结果的反
endmodule
