//SystemVerilog
// 顶层模块
module xor_and_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 使用布尔代数简化表达式：
    // 原始: Y = (A ^ B) & (A | C)
    // 展开: Y = (A & ~B | ~A & B) & (A | C)
    // 分配: Y = (A & ~B & (A | C)) | (~A & B & (A | C))
    // 简化: Y = (A & ~B & A) | (A & ~B & C) | (~A & B & A) | (~A & B & C)
    // 进一步简化: Y = (A & ~B & C) | (~A & B & C) = (A^B) & C
    
    assign Y = (A ^ B) & C;
    
endmodule