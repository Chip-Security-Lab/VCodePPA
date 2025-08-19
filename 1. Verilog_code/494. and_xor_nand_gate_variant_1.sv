//SystemVerilog
// 顶层模块
module and_xor_nand_gate (
    input wire A, B, C,
    output wire Y
);
    // 直接实现组合逻辑而不使用中间信号
    // 原始逻辑: Y = (A & B) ^ (~(C & A))
    // 简化为: Y = (A & B) ^ (~C | ~A)
    // 进一步简化为: Y = (A & B & (C & A)) | (~(A & B) & ~(C & A))
    // 最终简化为: Y = (A & B & C) | (~B & ~C)
    assign Y = (A & B & C) | (~B & ~C);
endmodule