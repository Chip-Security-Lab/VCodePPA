module selective_bit_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data, pattern, bit_select,
    output match
);
    // Only compare bits where bit_select is 1
    wire [WIDTH-1:0] masked_diff = (data ^ pattern) & bit_select;
    assign match = (masked_diff == 0);
endmodule