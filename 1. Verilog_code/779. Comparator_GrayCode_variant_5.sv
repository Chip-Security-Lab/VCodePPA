//SystemVerilog
// 顶层模块
module Comparator_GrayCode #(
    parameter WIDTH = 4,
    parameter THRESHOLD = 1      // 允许差异位数
)(
    input  [WIDTH-1:0] gray_code_a,
    input  [WIDTH-1:0] gray_code_b,
    output         is_adjacent  
);
    // 内部信号
    wire [WIDTH-1:0] diff_bits;
    wire [$clog2(WIDTH)+1:0] pop_count;
    
    // 实例化差异计算模块
    DiffCalculator #(
        .WIDTH(WIDTH)
    ) diff_calc (
        .gray_code_a(gray_code_a),
        .gray_code_b(gray_code_b),
        .diff_bits(diff_bits)
    );
    
    // 实例化汉明距离计算模块
    HammingDistance #(
        .WIDTH(WIDTH)
    ) hamming_calc (
        .diff_bits(diff_bits),
        .pop_count(pop_count)
    );
    
    // 实例化比较模块
    ThresholdComparator #(
        .WIDTH($clog2(WIDTH)+1),
        .THRESHOLD(THRESHOLD)
    ) threshold_comp (
        .pop_count(pop_count),
        .is_adjacent(is_adjacent)
    );
    
endmodule

// 差异计算模块
module DiffCalculator #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] gray_code_a,
    input  [WIDTH-1:0] gray_code_b,
    output [WIDTH-1:0] diff_bits
);
    assign diff_bits = gray_code_a ^ gray_code_b;  // 计算差异位
endmodule

// 汉明距离计算模块 - 使用树形结构
module HammingDistance #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] diff_bits,
    output [$clog2(WIDTH)+1:0] pop_count
);
    // 树形加法器结构计算汉明距离，降低逻辑深度
    wire [$clog2(WIDTH)+1:0] level1_sum;
    wire [$clog2(WIDTH)+1:0] level2_sum;
    
    // 第一层加法
    assign level1_sum[0] = diff_bits[0] + diff_bits[1];
    assign level1_sum[1] = diff_bits[2] + diff_bits[3];
    
    // 第二层加法
    assign level2_sum = level1_sum[0] + level1_sum[1];
    
    // 输出结果
    assign pop_count = level2_sum;
endmodule

// 阈值比较模块
module ThresholdComparator #(
    parameter WIDTH = 3,
    parameter THRESHOLD = 1
)(
    input  [WIDTH-1:0] pop_count,
    output reg is_adjacent
);
    always @(*) begin
        is_adjacent = (pop_count <= THRESHOLD);
    end
endmodule