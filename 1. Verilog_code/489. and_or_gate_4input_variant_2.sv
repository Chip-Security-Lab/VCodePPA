//SystemVerilog
///////////////////////////////////////////
// File: and_or_gate_4input_top.v
// Top module of the 4-input AND-OR gate
///////////////////////////////////////////

module and_or_gate_4input (
    input wire A, B, C, D,   // 四个输入
    output wire Y            // 输出Y
);
    // 使用组合赋值直接实现功能
    // (A·B)+(C·D) 表达式直接实现，减少中间信号和模块层次
    assign Y = (A & B) | (C & D);
endmodule

///////////////////////////////////////////
// File: and_gate.v
// 2-input AND gate module
///////////////////////////////////////////

module and_gate (
    input wire in1, in2,
    output wire out
);
    // 使用阻塞赋值提高仿真效率
    assign out = in1 & in2;
endmodule

///////////////////////////////////////////
// File: or_gate.v
// 2-input OR gate module
///////////////////////////////////////////

module or_gate (
    input wire in1, in2,
    output wire out
);
    // 使用阻塞赋值提高仿真效率
    assign out = in1 | in2;
endmodule