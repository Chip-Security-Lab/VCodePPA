module multi_operand_equality #(
    parameter OPERAND_WIDTH = 4,
    parameter NUM_OPERANDS = 4
)(
    input [OPERAND_WIDTH-1:0] operands [0:NUM_OPERANDS-1],
    output all_equal,    // High when all operands are identical
    output any_equal,    // High when at least two operands are equal
    output [NUM_OPERANDS-1:0] match_mask // Bit mask of operands matching operands[0]
);
    // Generate match comparisons for each operand against the first operand
    genvar i;
    wire [NUM_OPERANDS-1:0] match_with_first;
    
    generate
        for (i = 0; i < NUM_OPERANDS; i = i + 1) begin : match_gen
            assign match_with_first[i] = (operands[i] == operands[0]);
        end
    endgenerate
    
    // Check if all operands match the first one (all are equal)
    assign all_equal = &match_with_first;
    
    // Any equal detection requires pairwise comparison
    // Calculate number of pairs
    localparam NUM_PAIRS = (NUM_OPERANDS * (NUM_OPERANDS - 1)) / 2;
    wire [NUM_PAIRS-1:0] pairwise_equal;
    
    // Generate pairwise comparisons
    genvar j, k;
    generate
        for (j = 0; j < NUM_OPERANDS-1; j = j + 1) begin : outer_loop
            for (k = j + 1; k < NUM_OPERANDS; k = k + 1) begin : inner_loop
                // Calculate index based on j and k
                localparam idx = j * NUM_OPERANDS - (j * (j + 1)) / 2 + k - j - 1;
                assign pairwise_equal[idx] = (operands[j] == operands[k]);
            end
        end
    endgenerate
    
    // Any equal is true if any pairwise comparison is true
    assign any_equal = |pairwise_equal;
    
    // Output match mask
    assign match_mask = match_with_first;
endmodule