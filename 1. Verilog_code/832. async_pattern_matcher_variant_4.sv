//SystemVerilog
module async_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output match_out
);

    // Comparator submodule
    comparator #(.WIDTH(WIDTH)) comp_inst (
        .data_in(data_in),
        .pattern(pattern),
        .match_out(match_out)
    );

endmodule

module comparator #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output match_out
);
    // Two's complement subtraction for comparison
    wire [WIDTH:0] diff;
    wire [WIDTH-1:0] pattern_comp;
    
    // Generate two's complement of pattern
    assign pattern_comp = ~pattern + 1'b1;
    
    // Add data_in and two's complement of pattern
    assign diff = {1'b0, data_in} + {1'b0, pattern_comp};
    
    // Match when difference is zero
    assign match_out = (diff[WIDTH-1:0] == 0);
endmodule