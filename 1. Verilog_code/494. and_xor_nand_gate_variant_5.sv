//SystemVerilog
// 顶层模块 - 优化后的逻辑实现
module and_xor_nand_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 直接使用布尔表达式实现，避免多级逻辑和子模块开销
    // 原始逻辑:
    // term1 = A & B & C
    // term2 = ~A & ~(B & C) = ~A & (~B | ~C)
    // term3 = A & ~B & ~C
    // Y = term1 | term2 | term3
    
    // 通过布尔代数简化:
    // = (A & B & C) | (~A & (~B | ~C)) | (A & ~B & ~C)
    // = (A & B & C) | (~A & (~B | ~C)) | (A & ~B & ~C)
    // = (A & B & C) | (~A & ~B) | (~A & ~C) | (A & ~B & ~C)
    // = (A & B & C) | (~A & ~B) | (~A & ~C) | (A & ~B & ~C)
    
    assign Y = (A & B & C) | (~A & (~B | ~C)) | (A & ~B & ~C);
endmodule