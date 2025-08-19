//SystemVerilog
module wildcard_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data, pattern, mask,
    output match_result
);
    // 简化比较逻辑 - 直接使用XOR和掩码实现模式匹配
    // 对于掩码位为1的位置，视为"不关心"，始终匹配
    // 对于掩码位为0的位置，只有当数据与模式相等时才匹配
    wire [WIDTH-1:0] comparison = data ^ pattern;
    wire [WIDTH-1:0] match_bits = ~(comparison & ~mask);
    
    // 所有位都匹配时才返回1
    assign match_result = &match_bits;
endmodule