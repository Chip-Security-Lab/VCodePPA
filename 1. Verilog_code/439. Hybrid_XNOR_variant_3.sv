//SystemVerilog
// 顶层模块
module Hybrid_XNOR(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] res
);
    // 内部连线
    wire [7:0] shifted_pattern;
    
    // 实例化子模块
    Pattern_Generator pattern_gen (
        .ctrl(ctrl),
        .shifted_pattern(shifted_pattern)
    );
    
    Bit_Operator bit_op (
        .base(base),
        .pattern(shifted_pattern),
        .result(res)
    );
endmodule

// 子模块：模式生成器
module Pattern_Generator(
    input [1:0] ctrl,
    output [7:0] shifted_pattern
);
    // 常量模式定义
    localparam PATTERN = 8'h0F;
    
    // 计算模块
    Shift_Calculator shift_calc (
        .ctrl(ctrl),
        .pattern(PATTERN),
        .shifted_pattern(shifted_pattern)
    );
endmodule

// 子模块：移位计算器
module Shift_Calculator(
    input [1:0] ctrl,
    input [7:0] pattern,
    output [7:0] shifted_pattern
);
    // 移位量计算
    wire [3:0] shift_amount;
    
    // 优化计算逻辑，使用左移一位替代乘法
    assign shift_amount = {ctrl, 1'b0};  // 等同于 ctrl * 2
    
    // 执行移位操作
    assign shifted_pattern = pattern << shift_amount;
endmodule

// 子模块：位操作器
module Bit_Operator(
    input [7:0] base,
    input [7:0] pattern,
    output [7:0] result
);
    // 逻辑操作子模块
    XNOR_Logic xnor_logic (
        .operand_a(base),
        .operand_b(pattern),
        .xnor_result(result)
    );
endmodule

// 子模块：XNOR逻辑
module XNOR_Logic(
    input [7:0] operand_a,
    input [7:0] operand_b,
    output [7:0] xnor_result
);
    // 执行XNOR操作
    assign xnor_result = ~(operand_a ^ operand_b);
endmodule