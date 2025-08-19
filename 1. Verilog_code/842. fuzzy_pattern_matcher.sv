module fuzzy_pattern_matcher #(parameter W = 8, MAX_MISMATCHES = 2) (
    input [W-1:0] data, pattern,
    output match
);
    wire [W-1:0] diff = data ^ pattern; // XOR to find differences
    
    integer i;
    reg [$clog2(W):0] mismatch_count;
    
    always @(*) begin
        mismatch_count = 0;
        for (i = 0; i < W; i = i + 1)
            if (diff[i]) mismatch_count = mismatch_count + 1;
    end
    
    assign match = (mismatch_count <= MAX_MISMATCHES);
endmodule