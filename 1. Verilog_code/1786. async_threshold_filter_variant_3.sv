//SystemVerilog
module async_threshold_filter #(
    parameter DATA_W = 8
)(
    input [DATA_W-1:0] in_signal,
    input [DATA_W-1:0] high_thresh,
    input [DATA_W-1:0] low_thresh,
    input current_state,
    output next_state
);
    // Internal signals for comparisons using conditional inverse subtractor
    wire [DATA_W:0] sub_result_low, sub_result_high;
    wire less_than_low, greater_than_high;
    
    // Conditional inverse subtractor for low threshold comparison
    // If current_state=1, we need to check if in_signal < low_thresh
    assign sub_result_low = (in_signal ^ {DATA_W{1'b1}}) + low_thresh + 1'b1;
    assign less_than_low = sub_result_low[DATA_W];
    
    // Conditional inverse subtractor for high threshold comparison
    // If current_state=0, we need to check if in_signal > high_thresh
    assign sub_result_high = (high_thresh ^ {DATA_W{1'b1}}) + in_signal + 1'b1;
    assign greater_than_high = sub_result_high[DATA_W];
    
    // Schmitt trigger behavior using subtractor results
    assign next_state = current_state ? 
                      (less_than_low ? 1'b0 : 1'b1) :
                      (greater_than_high ? 1'b1 : 1'b0);
endmodule