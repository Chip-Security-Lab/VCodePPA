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
    // Internal signals
    wire comparison_high, comparison_low;
    
    // Instantiate comparator modules
    threshold_comparator #(
        .DATA_W(DATA_W),
        .COMPARE_TYPE("GREATER")
    ) high_comparator (
        .signal(in_signal),
        .threshold(high_thresh),
        .result(comparison_high)
    );
    
    threshold_comparator #(
        .DATA_W(DATA_W),
        .COMPARE_TYPE("LESS")
    ) low_comparator (
        .signal(in_signal),
        .threshold(low_thresh),
        .result(comparison_low)
    );
    
    // Instantiate state logic module
    state_decision_logic state_logic (
        .current_state(current_state),
        .high_comparison(comparison_high),
        .low_comparison(comparison_low),
        .next_state(next_state)
    );
endmodule

module threshold_comparator #(
    parameter DATA_W = 8,
    parameter COMPARE_TYPE = "GREATER" // "GREATER" or "LESS"
)(
    input [DATA_W-1:0] signal,
    input [DATA_W-1:0] threshold,
    output reg result
);
    always @(*) begin
        if (COMPARE_TYPE == "GREATER")
            result = (signal > threshold);
        else if (COMPARE_TYPE == "LESS")
            result = (signal < threshold);
        else
            result = 1'b0; // Default case
    end
endmodule

module state_decision_logic (
    input current_state,
    input high_comparison,
    input low_comparison,
    output reg next_state
);
    always @(*) begin
        if (current_state)
            next_state = low_comparison ? 1'b0 : 1'b1;
        else
            next_state = high_comparison ? 1'b1 : 1'b0;
    end
endmodule