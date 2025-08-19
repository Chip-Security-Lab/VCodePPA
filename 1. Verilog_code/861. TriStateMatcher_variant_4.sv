//SystemVerilog
// 顶层模块
module TriStateMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern, 
    input [WIDTH-1:0] mask,
    output match
);

    wire [WIDTH-1:0] masked_data;
    wire [WIDTH-1:0] masked_pattern;
    wire comparison_result;

    // 数据掩码处理子模块
    DataMasker #(.WIDTH(WIDTH)) data_masker (
        .data(data),
        .mask(mask),
        .masked_data(masked_data)
    );

    // 模式掩码处理子模块  
    PatternMasker #(.WIDTH(WIDTH)) pattern_masker (
        .pattern(pattern),
        .mask(mask),
        .masked_pattern(masked_pattern)
    );

    // 比较器子模块 - 使用借位减法器实现
    BorrowSubtractorComparator #(.WIDTH(WIDTH)) comparator (
        .masked_data(masked_data),
        .masked_pattern(masked_pattern),
        .match(match)
    );

endmodule

// 数据掩码处理子模块
module DataMasker #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] mask,
    output [WIDTH-1:0] masked_data
);
    assign masked_data = data & mask;
endmodule

// 模式掩码处理子模块
module PatternMasker #(parameter WIDTH=8) (
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] mask,
    output [WIDTH-1:0] masked_pattern
);
    assign masked_pattern = pattern & mask;
endmodule

// 基于借位减法器的比较器子模块
module BorrowSubtractorComparator #(parameter WIDTH=8) (
    input [WIDTH-1:0] masked_data,
    input [WIDTH-1:0] masked_pattern,
    output match
);
    wire [WIDTH-1:0] difference;
    wire [WIDTH:0] borrow;
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 使用借位减法器逐位计算差值
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sub_bit
            assign difference[i] = masked_data[i] ^ masked_pattern[i] ^ borrow[i];
            assign borrow[i+1] = (~masked_data[i] & masked_pattern[i]) | 
                                 (~masked_data[i] & borrow[i]) | 
                                 (masked_pattern[i] & borrow[i]);
        end
    endgenerate
    
    // 如果所有位的差值为0，则匹配成功
    assign match = (difference == {WIDTH{1'b0}});
endmodule