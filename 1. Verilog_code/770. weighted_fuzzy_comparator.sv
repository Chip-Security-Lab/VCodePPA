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
    // Split the comparison based on significance
    wire [WIDTH-1:0] difference = data_a ^ data_b;
    wire [WIDTH-1:0] high_sig_diff = difference & WEIGHT_MASK;
    wire [WIDTH-1:0] low_sig_diff = difference & ~WEIGHT_MASK;
    
    // Match flags
    assign match_high_significance = (high_sig_diff == {WIDTH{1'b0}});
    assign match_low_significance = (low_sig_diff == {WIDTH{1'b0}});
    assign match_all = match_high_significance && match_low_significance;
    
    // Calculate similarity score (0-10)
    // More weight given to high significance bits
    reg [5:0] weighted_match;
    integer i;
    
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
    
    // 编译时计算除数
    localparam DIVISOR = 2 * count_ones(WEIGHT_MASK) + (WIDTH - count_ones(WEIGHT_MASK));
    
    always @(*) begin
        weighted_match = 0;
        
        // For each bit that matches, add its weight to the score
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (!difference[i]) begin
                if (WEIGHT_MASK[i])
                    weighted_match = weighted_match + 2;  // High significance bit match
                else
                    weighted_match = weighted_match + 1;  // Low significance bit match
            end
        end
    end
    
    // Scale to 0-10 range
    assign similarity_score = (weighted_match * 10) / DIVISOR;
endmodule