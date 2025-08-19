//SystemVerilog
module selective_bit_matcher #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] bit_select,
    output match
);

    // 使用优先级编码器结构优化比较逻辑
    wire [WIDTH-1:0] diff_bits;
    wire [WIDTH-1:0] active_bits;
    wire [WIDTH-1:0] match_bits;
    
    // 计算差异位
    assign diff_bits = data ^ pattern;
    
    // 只考虑被选择的位
    assign active_bits = diff_bits & bit_select;
    
    // 使用优先级编码器结构检测是否所有活动位都匹配
    assign match_bits = active_bits | ~bit_select;
    
    // 最终匹配结果
    assign match = &match_bits;

endmodule