//SystemVerilog
// 顶层模块
module xor_and_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 布尔表达式简化实现
    // 原始功能: Y = (A ^ B) & (A | C)
    // 布尔代数展开：Y = (A&~B | ~A&B) & (A | C)
    // 代入分配律: Y = (A&~B)&(A|C) | (~A&B)&(A|C)
    // 化简: Y = A&~B&(A|C) | ~A&B&(A|C)
    // 进一步: Y = A&~B | ~A&B&(A|C)
    // 由于A&~A=0，简化为: Y = A&~B | B&C
    
    assign Y = (A & ~B) | (B & C);
endmodule