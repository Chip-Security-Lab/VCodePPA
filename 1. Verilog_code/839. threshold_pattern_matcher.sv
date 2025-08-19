module threshold_pattern_matcher #(parameter W = 16, THRESHOLD = 3) (
    input [W-1:0] data, pattern,
    output match_flag
);
    // Count matching bits
    wire [W-1:0] xnor_result = ~(data ^ pattern);
    integer i;
    reg [$clog2(W+1)-1:0] match_count;
    
    always @(*) begin
        match_count = 0;
        for (i = 0; i < W; i = i + 1)
            if (xnor_result[i]) match_count = match_count + 1;
    end
    
    assign match_flag = (match_count >= THRESHOLD);
endmodule