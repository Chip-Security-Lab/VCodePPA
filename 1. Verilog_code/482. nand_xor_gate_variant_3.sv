//SystemVerilog
module nand_xor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 将 (~A | ~B) ^ C 简化
    // 应用布尔代数展开: (~A | ~B) ^ C = (~A ^ C) | (~B ^ C)
    // 进一步简化: (~A ^ C) = A ^ C，因为XOR具有相反性质
    // 同理: (~B ^ C) = B ^ C
    // 因此: (~A | ~B) ^ C = (A ^ C) | (B ^ C)
    assign Y = (A ^ C) | (B ^ C);
endmodule