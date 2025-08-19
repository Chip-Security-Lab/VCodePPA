//SystemVerilog
// Top-level module with hierarchical structure
module Compare_XNOR (
    input [7:0] a, b,
    output eq_flag
);
    // Internal signals for bit-level comparison
    wire [7:0] bit_compare;
    
    // Instantiate bit-wise comparator
    BitWiseComparator bit_comparator (
        .a(a),
        .b(b),
        .bit_match(bit_compare)
    );
    
    // Instantiate equality detector
    EqualityDetector equality_detector (
        .bit_match(bit_compare),
        .eq_flag(eq_flag)
    );
    
endmodule

// Sub-module for bit-wise comparison
module BitWiseComparator (
    input [7:0] a, b,
    output [7:0] bit_match
);
    // Perform XNOR operation for each bit pair
    // XNOR will produce 1 when bits are equal
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_comp
            assign bit_match[i] = ~(a[i] ^ b[i]);
        end
    endgenerate
endmodule

// Sub-module for detecting equality from bit-wise comparison
module EqualityDetector (
    input [7:0] bit_match,
    output eq_flag
);
    // All bits must match for equality
    assign eq_flag = &bit_match;
endmodule