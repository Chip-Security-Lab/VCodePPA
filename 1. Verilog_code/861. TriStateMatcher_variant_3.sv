//SystemVerilog
module TriStateMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] mask,
    output match
);
    wire [WIDTH-1:0] masked_data, masked_pattern;
    wire [WIDTH-1:0] xor_result;
    
    // 应用掩码
    assign masked_data = data & mask;
    assign masked_pattern = pattern & mask;
    
    // 使用异或运算比较两个掩码后的值
    assign xor_result = masked_data ^ masked_pattern;
    
    // 如果异或结果为0，则匹配
    assign match = ~(|xor_result);
endmodule