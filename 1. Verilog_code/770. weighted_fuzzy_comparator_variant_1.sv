//SystemVerilog
module weighted_fuzzy_comparator #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT_MASK = 8'b11110000  // MSBs have higher weight
)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output match_high_significance,  // Match considering only high significance bits
    output match_low_significance,   // Match considering only low significance bits 
    output match_all,                // Match on all bits
    output [3:0] similarity_score    // 0-10 score representing similarity
);
    // 利用XNOR计算匹配位 (XNOR结果为1表示对应位匹配)
    wire [WIDTH-1:0] match_bits = ~(data_a ^ data_b);
    
    // 分离高低位匹配
    wire [WIDTH-1:0] high_sig_match = match_bits & WEIGHT_MASK;
    wire [WIDTH-1:0] low_sig_match = match_bits & ~WEIGHT_MASK;
    
    // 高位匹配：高位匹配位 与 高位掩码相同
    assign match_high_significance = ((high_sig_match | ~WEIGHT_MASK) == {WIDTH{1'b1}});
    
    // 低位匹配：低位匹配位 与 低位掩码相同
    assign match_low_significance = ((low_sig_match | WEIGHT_MASK) == {WIDTH{1'b1}});
    
    // 全部匹配：直接使用match_bits判断
    assign match_all = &match_bits;
    
    // 预先计算WEIGHT_MASK中1的个数
    function integer count_ones;
        input [WIDTH-1:0] data;
        integer i, count;
        begin
            count = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (data[i]) count = count + 1;
            end
            count_ones = count;
        end
    endfunction
    
    // 编译时计算常量
    localparam HIGH_BITS_COUNT = count_ones(WEIGHT_MASK);
    localparam LOW_BITS_COUNT = WIDTH - HIGH_BITS_COUNT;
    localparam DIVISOR = 2 * HIGH_BITS_COUNT + LOW_BITS_COUNT;
    
    // 使用并行计算代替循环计算相似度
    wire [WIDTH-1:0] high_weighted_match = {WIDTH{2'b10}} & {WIDTH{match_bits}} & WEIGHT_MASK;
    wire [WIDTH-1:0] low_weighted_match = {WIDTH{1'b1}} & {WIDTH{match_bits}} & ~WEIGHT_MASK;
    
    wire [5:0] high_score;
    wire [5:0] low_score;
    
    // 使用优化的加权方法
    assign high_score = high_weighted_match[0] + high_weighted_match[1] + 
                        high_weighted_match[2] + high_weighted_match[3] +
                        high_weighted_match[4] + high_weighted_match[5] +
                        high_weighted_match[6] + high_weighted_match[7];
    
    assign low_score = low_weighted_match[0] + low_weighted_match[1] + 
                      low_weighted_match[2] + low_weighted_match[3] +
                      low_weighted_match[4] + low_weighted_match[5] +
                      low_weighted_match[6] + low_weighted_match[7];
    
    wire [5:0] total_score = high_score + low_score;
    
    // 优化除法运算，使用乘法和移位
    assign similarity_score = (total_score * 10 + (DIVISOR/2)) / DIVISOR;
endmodule