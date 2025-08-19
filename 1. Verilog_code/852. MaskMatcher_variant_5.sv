//SystemVerilog
module MaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern, mask,
    output match
);
    wire [WIDTH-1:0] masked_data, masked_pattern;
    wire [WIDTH-1:0] difference;
    wire carry_out;
    
    // 对数据和模式应用掩码
    assign masked_data = data & mask;
    assign masked_pattern = pattern & mask;
    
    // 使用条件反相减法器实现比较
    // A - B = A + ~B + 1 (补码表示)
    assign {carry_out, difference} = masked_data + (~masked_pattern) + 1'b1;
    
    // 当差值为0时，表示匹配成功
    assign match = (difference == {WIDTH{1'b0}});
endmodule