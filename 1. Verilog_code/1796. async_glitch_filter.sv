module async_glitch_filter #(
    parameter GLITCH_THRESHOLD = 3
)(
    input [GLITCH_THRESHOLD-1:0] samples,
    output filtered_out
);
    // Count ones in the sample window
    function integer count_ones;
        input [GLITCH_THRESHOLD-1:0] bits;
        integer i;
        begin
            count_ones = 0;
            for (i = 0; i < GLITCH_THRESHOLD; i = i + 1)
                count_ones = count_ones + bits[i];
        end
    endfunction
    
    // Majority voting
    assign filtered_out = (count_ones(samples) > GLITCH_THRESHOLD/2);
endmodule