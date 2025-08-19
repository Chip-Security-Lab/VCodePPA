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
    
    // Any equal detection using carry-lookahead adder approach
    wire [NUM_OPERANDS-1:0] carry_propagate;
    wire [NUM_OPERANDS-1:0] carry_generate;
    wire [NUM_OPERANDS-1:0] carry_out;
    
    // Generate carry propagate and generate signals
    generate
        for (i = 0; i < NUM_OPERANDS-1; i = i + 1) begin : carry_gen
            assign carry_propagate[i] = (operands[i] == operands[i+1]);
            assign carry_generate[i] = (operands[i] == operands[i+1]);
        end
    endgenerate
    
    // Carry lookahead logic
    assign carry_out[0] = carry_generate[0];
    generate
        for (i = 1; i < NUM_OPERANDS-1; i = i + 1) begin : carry_lookahead
            assign carry_out[i] = carry_generate[i] | (carry_propagate[i] & carry_out[i-1]);
        end
    endgenerate
    
    // Any equal is true if any carry is generated
    assign any_equal = |carry_out;
    
    // Output match mask
    assign match_mask = match_with_first;
endmodule