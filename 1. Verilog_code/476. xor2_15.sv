module xor2_15 (
    input wire A, B,
    output wire Y
);
    wire notA, notB;
    not (notA, A);
    not (notB, B);
    assign Y = (A & notB) | (notA & B); // 使用基本门构建异或门
endmodule
