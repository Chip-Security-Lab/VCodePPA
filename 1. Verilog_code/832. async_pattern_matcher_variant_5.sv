//SystemVerilog
module async_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in, pattern,
    output match_out
);
    // 直接比较数据和模式是否相等
    // 使用XNOR运算简化了原来的减法和借位检测逻辑
    wire [WIDTH-1:0] comparison;
    
    // 对每一位执行XNOR操作，结果为1表示该位匹配
    assign comparison = ~(data_in ^ pattern);
    
    // 只有当所有位都匹配时输出为1
    assign match_out = &comparison;
endmodule