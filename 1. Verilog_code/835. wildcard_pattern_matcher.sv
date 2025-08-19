module wildcard_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data, pattern, mask,
    output match_result
);
    // Mask: 0 = care bit, 1 = don't care bit
    wire [WIDTH-1:0] masked_data = data & ~mask;
    wire [WIDTH-1:0] masked_pattern = pattern & ~mask;
    assign match_result = (masked_data == masked_pattern);
endmodule