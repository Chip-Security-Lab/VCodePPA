module nor3_inverted (
    input wire A, B, C,
    output wire Y
);
    wire n1, n2;
    assign n1 = A | B;  // 先计算 A 和 B 的或运算
    assign n2 = n1 | C;  // 然后计算结果与 C 的或运算
    assign Y = ~n2;  // 最终输出为反转结果
endmodule
