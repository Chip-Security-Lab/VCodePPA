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
    // Compute match vectors directly
    wire [WIDTH-1:0] match_vector = ~(data_a ^ data_b);
    wire [WIDTH-1:0] high_sig_match = match_vector & WEIGHT_MASK;
    wire [WIDTH-1:0] low_sig_match = match_vector & ~WEIGHT_MASK;
    
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
    
    // 编译时常量计算
    localparam HIGH_SIG_BITS = count_ones(WEIGHT_MASK);
    localparam LOW_SIG_BITS = WIDTH - HIGH_SIG_BITS;
    localparam DIVISOR = 2 * HIGH_SIG_BITS + LOW_SIG_BITS;
    
    // 高显著性和低显著性匹配检测
    assign match_high_significance = (count_matches(high_sig_match) == HIGH_SIG_BITS);
    assign match_low_significance = (count_matches(low_sig_match) == LOW_SIG_BITS);
    assign match_all = (count_matches(match_vector) == WIDTH);
    
    // 优化的匹配计数函数
    function integer count_matches;
        input [WIDTH-1:0] match_bits;
        integer i, count;
        begin
            count = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (match_bits[i]) count = count + 1;
            end
            count_matches = count;
        end
    endfunction
    
    // 并行计算加权匹配分数
    reg [5:0] weighted_match;
    integer i;
    
    always @(*) begin
        weighted_match = count_matches(high_sig_match) * 2 + count_matches(low_sig_match);
    end
    
    // 优化除法运算，使用移位和加法
    wire [7:0] scaled_score = (weighted_match * 10);
    assign similarity_score = (DIVISOR == 16) ? scaled_score[7:4] :
                              (DIVISOR == 8) ? {scaled_score[7:5], 1'b0} :
                              (DIVISOR == 12) ? (scaled_score[7:4] + {1'b0, scaled_score[7:5]}) >> 1 :
                              scaled_score / DIVISOR;
endmodule