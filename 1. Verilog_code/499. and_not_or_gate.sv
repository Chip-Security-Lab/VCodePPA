module and_not_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = (A & B) & ~C | A;  // 与、非和或组合
endmodule
