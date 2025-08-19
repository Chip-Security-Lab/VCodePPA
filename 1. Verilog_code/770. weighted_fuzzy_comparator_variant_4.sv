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
    // Internal signals
    wire [WIDTH-1:0] difference;
    wire [WIDTH-1:0] high_sig_diff;
    wire [WIDTH-1:0] low_sig_diff;
    wire [5:0] weighted_match;
    
    // 预先计算WEIGHT_MASK中1的个数
    function integer count_ones;
        input [WIDTH-1:0] data;
        integer i, count;
        begin
            count = 0;
            i = 0;
            while (i < WIDTH) begin
                if (data[i]) count = count + 1;
                i = i + 1;
            end
            count_ones = count;
        end
    endfunction
    
    // 编译时计算除数
    localparam DIVISOR = 2 * count_ones(WEIGHT_MASK) + (WIDTH - count_ones(WEIGHT_MASK));
    
    // Instantiate the difference calculator module
    difference_calculator #(
        .WIDTH(WIDTH)
    ) diff_calc (
        .data_a(data_a),
        .data_b(data_b),
        .difference(difference),
        .high_sig_diff(high_sig_diff),
        .low_sig_diff(low_sig_diff),
        .weight_mask(WEIGHT_MASK)
    );
    
    // Instantiate the match detector module
    match_detector #(
        .WIDTH(WIDTH)
    ) match_detect (
        .high_sig_diff(high_sig_diff),
        .low_sig_diff(low_sig_diff),
        .match_high_significance(match_high_significance),
        .match_low_significance(match_low_significance),
        .match_all(match_all)
    );
    
    // Instantiate the similarity calculator module
    similarity_calculator #(
        .WIDTH(WIDTH)
    ) sim_calc (
        .difference(difference),
        .weight_mask(WEIGHT_MASK),
        .divisor(DIVISOR),
        .weighted_match(weighted_match)
    );
    
    // Instantiate the score scaler module
    score_scaler score_scale (
        .weighted_match(weighted_match),
        .divisor(DIVISOR),
        .similarity_score(similarity_score)
    );
    
endmodule

// Module to calculate difference between inputs
module difference_calculator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    input [WIDTH-1:0] weight_mask,
    output [WIDTH-1:0] difference,
    output [WIDTH-1:0] high_sig_diff,
    output [WIDTH-1:0] low_sig_diff
);
    // Calculate XOR difference between inputs
    assign difference = data_a ^ data_b;
    
    // Split into high and low significance components
    assign high_sig_diff = difference & weight_mask;
    assign low_sig_diff = difference & ~weight_mask;
endmodule

// Module to detect various match conditions
module match_detector #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] high_sig_diff,
    input [WIDTH-1:0] low_sig_diff,
    output match_high_significance,
    output match_low_significance,
    output match_all
);
    // Generate match flags based on differences
    assign match_high_significance = (high_sig_diff == {WIDTH{1'b0}});
    assign match_low_significance = (low_sig_diff == {WIDTH{1'b0}});
    assign match_all = match_high_significance && match_low_significance;
endmodule

// Module to calculate weighted similarity
module similarity_calculator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] difference,
    input [WIDTH-1:0] weight_mask,
    input [31:0] divisor,  // Made wider to accommodate parameter
    output [5:0] weighted_match
);
    // Calculate weighted similarity
    reg [5:0] match_calc;
    integer i;
    
    always @(*) begin
        match_calc = 0;
        
        // For each bit that matches, add its weight to the score
        i = 0;
        while (i < WIDTH) begin
            if (!difference[i]) begin
                if (weight_mask[i])
                    match_calc = match_calc + 2;  // High significance bit match
                else
                    match_calc = match_calc + 1;  // Low significance bit match
            end
            i = i + 1;
        end
    end
    
    assign weighted_match = match_calc;
endmodule

// Module to scale the similarity score to 0-10 range
module score_scaler (
    input [5:0] weighted_match,
    input [31:0] divisor,  // Made wider to accommodate parameter
    output [3:0] similarity_score
);
    // Scale to 0-10 range using fixed-point multiplication
    assign similarity_score = (weighted_match * 10) / divisor;
endmodule