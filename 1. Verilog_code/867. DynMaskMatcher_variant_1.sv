//SystemVerilog
module DynMaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] dynamic_mask,
    output match
);
    // Direct XNOR-based comparison of masked inputs
    // Only compare bits that are enabled by the mask
    wire [WIDTH-1:0] comparison;
    
    // Use XNOR operation to check equality bit by bit
    // If bits are equal, the result is 1, otherwise 0
    assign comparison = ~(masked_data ^ masked_pattern);
    
    // Apply mask directly in the comparison logic
    wire [WIDTH-1:0] masked_data = data & dynamic_mask;
    wire [WIDTH-1:0] masked_pattern = pattern & dynamic_mask;
    
    // If all bits that we care about (according to mask) match,
    // then the AND of all comparison bits will be 1
    assign match = &(comparison | ~dynamic_mask);
endmodule