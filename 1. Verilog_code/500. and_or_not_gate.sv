module and_or_not_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = (A & B) | (~C);  // 与、或和非组合
endmodule
