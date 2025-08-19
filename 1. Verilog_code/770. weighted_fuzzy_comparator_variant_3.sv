//SystemVerilog
module weighted_fuzzy_comparator #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT_MASK = 8'b11110000
)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output match_high_significance,
    output match_low_significance,
    output match_all,
    output [3:0] similarity_score
);
    // 优化位匹配计算
    wire [WIDTH-1:0] bit_matches = ~(data_a ^ data_b);
    
    // 优化高低位匹配计算
    wire [WIDTH-1:0] high_sig_matches = bit_matches & WEIGHT_MASK;
    wire [WIDTH-1:0] low_sig_matches = bit_matches & ~WEIGHT_MASK;
    
    // 优化匹配标志计算
    assign match_high_significance = &(high_sig_matches | ~WEIGHT_MASK);
    assign match_low_significance = &(low_sig_matches | WEIGHT_MASK);
    assign match_all = &bit_matches;
    
    // 优化相似度计算
    function [3:0] count_ones;
        input [WIDTH-1:0] data;
        reg [3:0] count;
        integer i;
        begin
            count = 0;
            for (i = 0; i < WIDTH; i = i + 1)
                count = count + data[i];
            count_ones = count;
        end
    endfunction
    
    // 预计算常量
    localparam HIGH_BITS_COUNT = count_ones(WEIGHT_MASK);
    localparam LOW_BITS_COUNT = WIDTH - HIGH_BITS_COUNT;
    localparam DIVISOR = (2 * HIGH_BITS_COUNT) + LOW_BITS_COUNT;
    
    // 优化权重计算
    wire [3:0] high_match_count = count_ones(high_sig_matches);
    wire [3:0] low_match_count = count_ones(low_sig_matches);
    
    // 使用移位和加法优化乘法
    wire [5:0] weighted_match = {high_match_count, 1'b0} + low_match_count;
    wire [9:0] scaled_match = {weighted_match, 1'b0} + {2'b00, weighted_match, 2'b00};
    
    // 优化除法运算
    assign similarity_score = scaled_match / DIVISOR;
endmodule