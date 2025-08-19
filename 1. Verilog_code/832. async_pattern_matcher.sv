module async_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in, pattern,
    output match_out
);
    // Pure combinational implementation
    assign match_out = (data_in == pattern);
endmodule