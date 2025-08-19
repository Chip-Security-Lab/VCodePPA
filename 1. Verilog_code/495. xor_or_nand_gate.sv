module xor_or_nand_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = (A ^ B) | ~(C & A);  // 异或、或和与非组合
endmodule
