module RedundantNOT(
    input a,
    output y
);
    wire n1, n2;
    not G1(n1, a);    // 冗余非门
    not G2(n2, n1);   // 实现双非结构
    not G3(y, n2);    // 最终输出
endmodule
