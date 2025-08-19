//SystemVerilog
// 顶层模块
module fuzzy_pattern_matcher #(parameter W = 8, MAX_MISMATCHES = 2) (
    input [W-1:0] data, pattern,
    output reg match
);
    wire [W-1:0] diff;
    wire [$clog2(W):0] mismatch_count;
    
    // 实例化差异计算模块
    diff_calculator #(W) diff_calc (
        .data(data),
        .pattern(pattern),
        .diff(diff)
    );
    
    // 实例化不匹配计数模块
    mismatch_counter #(W) mismatch_cnt (
        .diff(diff),
        .mismatch_count(mismatch_count)
    );
    
    // 实例化匹配判断模块
    match_detector #(W, MAX_MISMATCHES) match_det (
        .mismatch_count(mismatch_count),
        .match(match)
    );

endmodule

// 差异计算模块
module diff_calculator #(parameter W = 8) (
    input [W-1:0] data, pattern,
    output [W-1:0] diff
);
    assign diff = data ^ pattern;
endmodule

// 不匹配计数模块
module mismatch_counter #(parameter W = 8) (
    input [W-1:0] diff,
    output reg [$clog2(W):0] mismatch_count
);
    always @(*) begin
        case (W)
            8: begin
                mismatch_count = diff[0] + diff[1] + diff[2] + diff[3] + 
                                diff[4] + diff[5] + diff[6] + diff[7];
            end
            default: begin
                mismatch_count = 0;
                for (integer i = 0; i < W; i = i + 2) begin
                    if (i < W)     mismatch_count = mismatch_count + diff[i];
                    if (i+1 < W)   mismatch_count = mismatch_count + diff[i+1];
                end
            end
        endcase
    end
endmodule

// 匹配判断模块
module match_detector #(parameter W = 8, MAX_MISMATCHES = 2) (
    input [$clog2(W):0] mismatch_count,
    output reg match
);
    always @(*) begin
        if (MAX_MISMATCHES == 0)
            match = (mismatch_count == 0);
        else if (MAX_MISMATCHES == 1)
            match = (mismatch_count <= 1);
        else
            match = (mismatch_count <= MAX_MISMATCHES);
    end
endmodule