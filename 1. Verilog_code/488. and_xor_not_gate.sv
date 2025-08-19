module and_xor_not_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = ((A & B) ^ C) & ~A;  // 与、异或和非组合
endmodule
