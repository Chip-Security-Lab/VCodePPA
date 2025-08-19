module partial_pattern_matcher #(parameter W = 16, SLICE = 8) (
    input [W-1:0] data, pattern,
    input match_upper, // Control to select which half to match
    output match_result
);
    wire upper_match = (data[W-1:W-SLICE] == pattern[W-1:W-SLICE]);
    wire lower_match = (data[SLICE-1:0] == pattern[SLICE-1:0]);
    
    assign match_result = match_upper ? upper_match : lower_match;
endmodule