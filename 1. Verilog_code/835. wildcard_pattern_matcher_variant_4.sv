//SystemVerilog
module wildcard_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data, pattern, mask,
    output match_result
);
    // 使用异或运算和归约与运算优化匹配逻辑
    wire [WIDTH-1:0] diff = (data ^ pattern) & ~mask;
    assign match_result = ~|diff;
endmodule