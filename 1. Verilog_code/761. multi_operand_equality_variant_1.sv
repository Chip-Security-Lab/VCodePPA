//SystemVerilog
//===========================================================================
// Top Module - Multi-operand Equality Detector
//===========================================================================
module multi_operand_equality #(
    parameter OPERAND_WIDTH = 4,
    parameter NUM_OPERANDS = 4
)(
    input [OPERAND_WIDTH-1:0] operands [0:NUM_OPERANDS-1],
    output all_equal,    // High when all operands are identical
    output any_equal,    // High when at least two operands are equal
    output [NUM_OPERANDS-1:0] match_mask // Bit mask of operands matching operands[0]
);
    // Interconnect signals between sub-modules
    wire [NUM_OPERANDS-1:0] first_match_result;
    wire [(NUM_OPERANDS * (NUM_OPERANDS - 1)) / 2 - 1:0] pairwise_result;
    
    // Instantiate first match detector module
    first_match_detector #(
        .OPERAND_WIDTH(OPERAND_WIDTH),
        .NUM_OPERANDS(NUM_OPERANDS)
    ) first_match_inst (
        .operands(operands),
        .match_with_first(first_match_result)
    );
    
    // Instantiate pairwise comparator module
    pairwise_comparator #(
        .OPERAND_WIDTH(OPERAND_WIDTH),
        .NUM_OPERANDS(NUM_OPERANDS)
    ) pairwise_comp_inst (
        .operands(operands),
        .pairwise_equal(pairwise_result)
    );
    
    // Instantiate result processor module
    result_processor #(
        .NUM_OPERANDS(NUM_OPERANDS)
    ) result_proc_inst (
        .match_with_first(first_match_result),
        .pairwise_equal(pairwise_result),
        .all_equal(all_equal),
        .any_equal(any_equal),
        .match_mask(match_mask)
    );
    
endmodule

//===========================================================================
// Sub-Module 1 - First Match Detector with LUT-based Subtraction
//===========================================================================
module first_match_detector #(
    parameter OPERAND_WIDTH = 4,
    parameter NUM_OPERANDS = 4
)(
    input [OPERAND_WIDTH-1:0] operands [0:NUM_OPERANDS-1],
    output [NUM_OPERANDS-1:0] match_with_first
);
    // LUT for 4-bit subtraction result
    reg [OPERAND_WIDTH-1:0] sub_lut [0:255];
    integer i;
    
    // Initialize LUT
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i[7:4] - i[3:0];
        end
    end
    
    // Generate match comparisons for each operand against the first operand
    genvar j;
    
    generate
        for (j = 0; j < NUM_OPERANDS; j = j + 1) begin : match_gen
            wire [OPERAND_WIDTH-1:0] diff;
            wire [7:0] lut_addr;
            
            // Form LUT address by concatenating operands
            assign lut_addr = {operands[j], operands[0]};
            
            // Get difference from LUT
            assign diff = sub_lut[lut_addr];
            
            // Check if difference is zero
            assign match_with_first[j] = (diff == 0);
        end
    endgenerate
endmodule

//===========================================================================
// Sub-Module 2 - Pairwise Comparator with LUT-based Subtraction
//===========================================================================
module pairwise_comparator #(
    parameter OPERAND_WIDTH = 4,
    parameter NUM_OPERANDS = 4
)(
    input [OPERAND_WIDTH-1:0] operands [0:NUM_OPERANDS-1],
    output [(NUM_OPERANDS * (NUM_OPERANDS - 1)) / 2 - 1:0] pairwise_equal
);
    // Calculate number of pairs
    localparam NUM_PAIRS = (NUM_OPERANDS * (NUM_OPERANDS - 1)) / 2;
    
    // LUT for 4-bit subtraction result
    reg [OPERAND_WIDTH-1:0] sub_lut [0:255];
    integer i;
    
    // Initialize LUT
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i[7:4] - i[3:0];
        end
    end
    
    // Generate pairwise comparisons
    genvar j, k;
    
    generate
        for (j = 0; j < NUM_OPERANDS-1; j = j + 1) begin : outer_loop
            for (k = j + 1; k < NUM_OPERANDS; k = k + 1) begin : inner_loop
                // Calculate index based on j and k
                localparam idx = j * NUM_OPERANDS - (j * (j + 1)) / 2 + k - j - 1;
                
                wire [OPERAND_WIDTH-1:0] diff;
                wire [7:0] lut_addr;
                
                // Form LUT address by concatenating operands
                assign lut_addr = {operands[j], operands[k]};
                
                // Get difference from LUT
                assign diff = sub_lut[lut_addr];
                
                // Check if difference is zero
                assign pairwise_equal[idx] = (diff == 0);
            end
        end
    endgenerate
endmodule

//===========================================================================
// Sub-Module 3 - Result Processor
//===========================================================================
module result_processor #(
    parameter NUM_OPERANDS = 4
)(
    input [NUM_OPERANDS-1:0] match_with_first,
    input [(NUM_OPERANDS * (NUM_OPERANDS - 1)) / 2 - 1:0] pairwise_equal,
    output all_equal,
    output any_equal,
    output [NUM_OPERANDS-1:0] match_mask
);
    // Check if all operands match the first one (all are equal)
    assign all_equal = &match_with_first;
    
    // Any equal is true if any pairwise comparison is true
    assign any_equal = |pairwise_equal;
    
    // Output match mask directly from first match detector result
    assign match_mask = match_with_first;
endmodule