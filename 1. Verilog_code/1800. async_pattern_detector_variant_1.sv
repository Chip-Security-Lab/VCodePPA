//SystemVerilog
module async_pattern_detector #(
    parameter PATTERN_W = 8,
    parameter PATTERN = 8'b10101010
)(
    input [PATTERN_W-1:0] data_in,
    input [PATTERN_W-1:0] mask,
    output pattern_detected
);
    // Pre-compute masked pattern at synthesis time
    localparam [PATTERN_W-1:0] MASKED_PATTERN = PATTERN;
    
    // Only care about masked bits - direct XNOR implementation
    wire [PATTERN_W-1:0] xnor_result;
    
    genvar i;
    generate
        for (i = 0; i < PATTERN_W; i = i + 1) begin : gen_compare
            // XNOR implementation: ~(A^B) = A~^B
            // Only consider bits where mask is 1
            assign xnor_result[i] = mask[i] ? ~(data_in[i] ^ MASKED_PATTERN[i]) : 1'b1;
        end
    endgenerate
    
    // AND reduction - all bits must match where mask=1
    assign pattern_detected = &xnor_result;
endmodule