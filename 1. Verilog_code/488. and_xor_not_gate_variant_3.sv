//SystemVerilog
module and_xor_not_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 简化表达式: ((A & B) ^ C) & ~A
    // 展开: ((A & B) ^ C) & ~A = (~(A & B) & C | (A & B) & ~C) & ~A
    // 由于 (A & B) & ~A = 0 (因为A和~A不能同时为1)
    // 所以简化为: (~(A & B) & C) & ~A = (C & ~A & ~(A & B))
    // 进一步简化: C & ~A & (~A | ~B) = C & ~A & ~B
    assign Y = C & ~A & ~B;  // 优化后的表达式
endmodule