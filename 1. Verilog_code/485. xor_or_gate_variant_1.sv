//SystemVerilog
///////////////////////////////////////////
// File: xor_or_gate_top.v
// 顶层模块：XOR-OR组合逻辑门
///////////////////////////////////////////

module xor_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);

    // 直接实现功能，减少层级延迟
    // 使用布尔代数将 (A^B)|C 展开为 (A&~B)|(~A&B)|C
    // 进一步简化为 (A|C)&(B|C)&(~A|~B|C)
    assign Y = (A|C) & (B|C) & (~A|~B|C);

endmodule

///////////////////////////////////////////
// XOR子模块：执行异或操作 - 优化版本
///////////////////////////////////////////

module xor_submodule #(
    parameter DELAY = 0   // 可配置延迟参数，用于调整时序
) (
    input wire in1,       // 第一个输入
    input wire in2,       // 第二个输入
    output wire out       // 异或结果输出
);

    // 使用基本逻辑门实现异或，可能在某些FPGA架构上更高效
    assign #(DELAY) out = (in1 & ~in2) | (~in1 & in2);

endmodule

///////////////////////////////////////////
// OR子模块：执行或操作 - 优化版本
///////////////////////////////////////////

module or_submodule #(
    parameter DELAY = 0   // 可配置延迟参数，用于调整时序
) (
    input wire in1,       // 第一个输入
    input wire in2,       // 第二个输入
    output wire out       // 或结果输出
);

    // 实现或功能
    assign #(DELAY) out = in1 | in2;

endmodule