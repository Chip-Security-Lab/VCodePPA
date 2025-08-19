module async_threshold_filter #(
    parameter DATA_W = 8
)(
    input [DATA_W-1:0] in_signal,
    input [DATA_W-1:0] high_thresh,
    input [DATA_W-1:0] low_thresh,
    input current_state,
    output next_state
);
    // Schmitt trigger behavior
    assign next_state = current_state ? 
                      (in_signal < low_thresh ? 1'b0 : 1'b1) :
                      (in_signal > high_thresh ? 1'b1 : 1'b0);
endmodule