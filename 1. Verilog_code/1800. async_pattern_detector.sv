module async_pattern_detector #(
    parameter PATTERN_W = 8,
    parameter PATTERN = 8'b10101010
)(
    input [PATTERN_W-1:0] data_in,
    input [PATTERN_W-1:0] mask,
    output pattern_detected
);
    // Matches pattern with mask (1 = care, 0 = don't care)
    wire [PATTERN_W-1:0] masked_data, masked_pattern, result;
    
    assign masked_data = data_in & mask;
    assign masked_pattern = PATTERN & mask;
    assign result = masked_data ^ masked_pattern;
    assign pattern_detected = (result == 0);
endmodule