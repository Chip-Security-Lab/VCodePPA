//SystemVerilog
module MaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern, mask,
    output match
);
    wire [WIDTH-1:0] masked_data, masked_pattern;
    wire [WIDTH-1:0] diff_result;
    wire borrow_out;
    
    // 生成掩码后的数据
    assign masked_data = data & mask;
    assign masked_pattern = pattern & mask;
    
    // 使用条件反相减法器算法实现比较
    // A - B = A + ~B + 1 (补码减法原理)
    assign {borrow_out, diff_result} = masked_data + (~masked_pattern) + 1'b1;
    
    // 当差值为0时，表示匹配
    assign match = (diff_result == {WIDTH{1'b0}});
endmodule