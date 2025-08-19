module xor_and_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = (A ^ B) & (A | C);  // 异或、与、或组合
endmodule
