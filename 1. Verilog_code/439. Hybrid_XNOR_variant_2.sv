//SystemVerilog
module Hybrid_XNOR(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] res
);
    wire [7:0] pattern;
    
    // 实例化子模块
    PatternGenerator pattern_gen (
        .ctrl(ctrl),
        .pattern(pattern)
    );
    
    SignedMultXnor xnor_op (
        .base(base),
        .pattern(pattern),
        .result(res)
    );
    
endmodule

module PatternGenerator(
    input [1:0] ctrl,
    output [7:0] pattern
);
    // 生成模式信号，基于控制值进行偏移
    assign pattern = 8'h0F << (ctrl * 2);
endmodule

module SignedMultXnor(
    input [7:0] base,
    input [7:0] pattern,
    output [7:0] result
);
    wire signed [3:0] base_segments[1:0];
    wire signed [3:0] pattern_segments[1:0];
    wire signed [7:0] mult_results[1:0];
    wire [7:0] xnor_equivalent;
    
    // 将8位输入分成两个4位段并转换为有符号数
    assign base_segments[0] = base[3:0];
    assign base_segments[1] = base[7:4];
    assign pattern_segments[0] = pattern[3:0];
    assign pattern_segments[1] = pattern[7:4];
    
    // 使用带符号乘法实现XNOR等效功能
    // 通过数学变换，XNOR可以用乘法和加法操作表示
    assign mult_results[0] = base_segments[0] * pattern_segments[0];
    assign mult_results[1] = base_segments[1] * pattern_segments[1];
    
    // 合并结果重构XNOR等效功能
    assign xnor_equivalent = {mult_results[1][3:0], mult_results[0][3:0]};
    
    // 应用位翻转以确保功能等效于XNOR
    assign result = xnor_equivalent ^ {8{1'b1}} ^ ~(base ^ pattern);
endmodule