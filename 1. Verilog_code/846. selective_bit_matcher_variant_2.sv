//SystemVerilog
module selective_bit_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data, pattern, bit_select,
    output match
);
    // XNOR implementation followed by mask and reduction
    wire [WIDTH-1:0] bit_matches = ~(data ^ pattern) | ~bit_select;
    
    // Reduced to AND operation of all bits
    assign match = &bit_matches;
endmodule