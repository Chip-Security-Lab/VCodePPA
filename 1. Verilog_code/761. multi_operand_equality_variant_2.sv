//SystemVerilog
module multi_operand_equality #(
    parameter OPERAND_WIDTH = 4,
    parameter NUM_OPERANDS = 4
)(
    input [OPERAND_WIDTH-1:0] operands [0:NUM_OPERANDS-1],
    output all_equal,
    output any_equal,
    output [NUM_OPERANDS-1:0] match_mask
);

    // Han-Carlson adder implementation
    wire [OPERAND_WIDTH-1:0] g [0:NUM_OPERANDS-1];
    wire [OPERAND_WIDTH-1:0] p [0:NUM_OPERANDS-1];
    wire [OPERAND_WIDTH-1:0] sum [0:NUM_OPERANDS-1];
    
    // Generate propagate and generate signals
    genvar i;
    generate
        for (i = 0; i < NUM_OPERANDS; i = i + 1) begin : pg_gen
            assign g[i] = operands[i] & operands[0];
            assign p[i] = operands[i] ^ operands[0];
        end
    endgenerate
    
    // Han-Carlson prefix computation
    wire [OPERAND_WIDTH-1:0] g1 [0:NUM_OPERANDS-1];
    wire [OPERAND_WIDTH-1:0] p1 [0:NUM_OPERANDS-1];
    
    // First level
    generate
        for (i = 0; i < NUM_OPERANDS; i = i + 1) begin : level1
            assign g1[i] = g[i] | (p[i] & g[0]);
            assign p1[i] = p[i] & p[0];
        end
    endgenerate
    
    // Second level
    wire [OPERAND_WIDTH-1:0] g2 [0:NUM_OPERANDS-1];
    wire [OPERAND_WIDTH-1:0] p2 [0:NUM_OPERANDS-1];
    
    generate
        for (i = 0; i < NUM_OPERANDS; i = i + 1) begin : level2
            assign g2[i] = g1[i] | (p1[i] & g1[0]);
            assign p2[i] = p1[i] & p1[0];
        end
    endgenerate
    
    // Final sum computation
    generate
        for (i = 0; i < NUM_OPERANDS; i = i + 1) begin : sum_gen
            assign sum[i] = p2[i] ^ g2[i];
        end
    endgenerate
    
    // Match detection
    wire [NUM_OPERANDS-1:0] match_with_first;
    generate
        for (i = 0; i < NUM_OPERANDS; i = i + 1) begin : match_gen
            assign match_with_first[i] = ~(|sum[i]);
        end
    endgenerate
    
    // All equal detection
    assign all_equal = &match_with_first;
    
    // Any equal detection
    localparam NUM_PAIRS = (NUM_OPERANDS * (NUM_OPERANDS - 1)) / 2;
    wire [NUM_PAIRS-1:0] pairwise_equal;
    
    genvar j, k;
    generate
        for (j = 0; j < NUM_OPERANDS-1; j = j + 1) begin : outer_loop
            for (k = j + 1; k < NUM_OPERANDS; k = k + 1) begin : inner_loop
                localparam idx = j * NUM_OPERANDS - (j * (j + 1)) / 2 + k - j - 1;
                assign pairwise_equal[idx] = ~(|(operands[j] ^ operands[k]));
            end
        end
    endgenerate
    
    assign any_equal = |pairwise_equal;
    assign match_mask = match_with_first;
endmodule