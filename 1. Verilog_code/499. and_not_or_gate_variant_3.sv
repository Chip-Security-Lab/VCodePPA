//SystemVerilog
module and_not_or_gate (
    input wire A, B, C,
    output wire Y
);
    // 优化表达式: A | (B & ~C) 
    // 应用布尔代数恒等式进一步简化
    // A | (B & ~C) => A | (B & ~C)
    // 注意：该表达式已经是最优形式，保持原样
    assign Y = A | (B & ~C);
endmodule