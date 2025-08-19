//SystemVerilog
// 顶层模块
module and_xor_nand_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 直接计算最终输出，无需中间连线
    // 原始逻辑: Y = (A & B) ^ (~(C & A))
    // 等价于: Y = (A & B) ^ (¬C | ¬A) (使用德摩根定律)
    // 进一步简化为: Y = (A & B & C) | (A & B & ¬A) | (¬(A & B) & ¬C) | (¬(A & B) & ¬A)
    // 由于 (A & ¬A) = 0，可以消除包含 (A & ¬A) 的项
    // 进一步简化: Y = (A & B & C) | (¬(A & B) & ¬C) | (¬B & ¬A)
    // 分配律简化: Y = (A & B & C) | (¬A & ¬C) | (¬B & ¬C)
    
    assign Y = (A & B & C) | (~A & ~C) | (~B & ~C);
    
endmodule