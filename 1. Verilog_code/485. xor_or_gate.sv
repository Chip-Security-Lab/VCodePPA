module xor_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = (A ^ B) | C;  // 异或和或组合
endmodule
