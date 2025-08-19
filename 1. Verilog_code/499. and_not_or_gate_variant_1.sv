//SystemVerilog
module and_not_or_gate (
    input wire A, B, C,   // 输入信号
    output wire Y         // 输出信号
);
    // 直接实现布尔表达式: Y = A | (A & B & ~C) = A | (B & ~C)
    assign Y = A | (B & ~C);
endmodule

// 输入逻辑处理子模块 - 处理A&B和~C的逻辑
module input_logic_stage (
    input wire A,
    input wire B,
    input wire C,
    output wire out
);
    // 简化实现: A & B & ~C
    assign out = A & B & ~C;
endmodule

// 输出逻辑处理子模块 - 处理最终的OR逻辑
module output_logic_stage (
    input wire stage1_result,
    input wire bypass_A,
    output wire out
);
    // 简化实现: stage1_result | bypass_A
    assign out = stage1_result | bypass_A;
endmodule

// 参数化基本逻辑门模块 - 提高代码复用性
module basic_logic_gate #(
    parameter string GATE_TYPE = "AND"  // 支持"AND", "OR", "NOT"
)(
    input wire in1,
    input wire in2,
    output wire out
);
    // 使用连续赋值代替always块，减少合成资源
    generate
        if (GATE_TYPE == "AND") 
            assign out = in1 & in2;
        else if (GATE_TYPE == "OR")
            assign out = in1 | in2;
        else if (GATE_TYPE == "NOT")
            assign out = ~in1;
        else
            assign out = 1'b0;
    endgenerate
endmodule