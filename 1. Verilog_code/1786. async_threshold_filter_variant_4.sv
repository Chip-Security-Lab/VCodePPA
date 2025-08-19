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
    // Intermediate variables for comparison results
    wire gt_result; // Greater than result
    wire lt_result; // Less than result
    
    // Intermediate signals for bit-level comparison
    wire [DATA_W-1:0] gt_bits;
    wire [DATA_W-1:0] lt_bits;
    
    // Multi-level comparison structure
    // First level: Bit-by-bit comparison
    genvar i;
    generate
        for (i = 0; i < DATA_W; i = i + 1) begin : gen_bit_compare
            // Compare bits for greater than
            assign gt_bits[i] = (in_signal[i] > high_thresh[i]) ? 1'b1 :
                               (in_signal[i] < high_thresh[i]) ? 1'b0 :
                               (i == 0) ? 1'b0 : gt_bits[i-1];
                               
            // Compare bits for less than
            assign lt_bits[i] = (in_signal[i] < low_thresh[i]) ? 1'b1 :
                              (in_signal[i] > low_thresh[i]) ? 1'b0 :
                              (i == 0) ? 1'b0 : lt_bits[i-1];
        end
    endgenerate
    
    // Second level: Final comparison results
    assign gt_result = gt_bits[DATA_W-1];
    assign lt_result = lt_bits[DATA_W-1];
    
    // Third level: State transition logic
    reg next_state_reg;
    
    always @(*) begin
        if (current_state == 1'b1) begin
            // If currently in high state
            if (lt_result == 1'b1) begin
                // Signal is below low threshold
                next_state_reg = 1'b0;
            end else begin
                // Signal is not below low threshold
                next_state_reg = 1'b1;
            end
        end else begin
            // If currently in low state
            if (gt_result == 1'b1) begin
                // Signal is above high threshold
                next_state_reg = 1'b1;
            end else begin
                // Signal is not above high threshold
                next_state_reg = 1'b0;
            end
        end
    end
    
    // Assign output
    assign next_state = next_state_reg;
endmodule