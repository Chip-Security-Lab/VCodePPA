//SystemVerilog
// 顶层模块
module xor_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 使用布尔代数优化: A^B|C = (A&~B)|(~A&B)|C = (A|C)&(~B|C)&(~A|B|C)
    // 这种逻辑表达式优化可减少关键路径延迟
    assign Y = (A | C) & (~B | C) & (~A | B | C);
endmodule

// XOR子模块 - 优化版本
module xor_submodule (
    input wire in1, in2,   // 输入信号
    output wire out        // 输出信号
);
    // 使用CMOS友好的XOR实现
    assign out = (in1 & ~in2) | (~in1 & in2);
endmodule

// OR子模块 - 优化版本
module or_submodule (
    input wire in1, in2,   // 输入信号
    output wire out        // 输出信号
);
    // 直接OR操作
    assign out = in1 | in2;
endmodule