//SystemVerilog
module and_xor_xnor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 原始: Y = (A & B) ^ (C ~^ A)
    // 中间简化: (~A & C) | (A & ~C) | (A & B & C)
    // 进一步简化: (A ^ C) | (A & B & C)
    assign Y = (A ^ C) | (A & B & C);
endmodule