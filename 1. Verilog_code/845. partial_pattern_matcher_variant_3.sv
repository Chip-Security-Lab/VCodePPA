//SystemVerilog
// SystemVerilog
// Top level module
module partial_pattern_matcher #(
    parameter W = 16,
    parameter SLICE = 8
)(
    input [W-1:0] data, pattern,
    input match_upper, // Control to select which half to match
    output match_result
);
    // Internal signals for connecting submodules
    wire upper_match, lower_match;
    
    // Instantiate upper half matcher
    slice_matcher #(
        .SLICE(SLICE)
    ) upper_half_matcher (
        .slice_data(data[W-1:W-SLICE]),
        .slice_pattern(pattern[W-1:W-SLICE]),
        .match_out(upper_match)
    );
    
    // Instantiate lower half matcher
    slice_matcher #(
        .SLICE(SLICE)
    ) lower_half_matcher (
        .slice_data(data[SLICE-1:0]),
        .slice_pattern(pattern[SLICE-1:0]),
        .match_out(lower_match)
    );
    
    // Instantiate result selector
    result_selector result_mux (
        .upper_match(upper_match),
        .lower_match(lower_match),
        .match_upper(match_upper),
        .match_result(match_result)
    );
endmodule

// Submodule for matching a slice of data against a pattern
module slice_matcher #(
    parameter SLICE = 8
)(
    input [SLICE-1:0] slice_data,
    input [SLICE-1:0] slice_pattern,
    output match_out
);
    wire [SLICE-1:0] diff;
    wire [SLICE:0] borrow;
    
    // Initial borrow is 0
    assign borrow[0] = 1'b0;
    
    // Conditional sum subtraction logic
    conditional_subtractor #(
        .WIDTH(SLICE)
    ) subtractor_inst (
        .minuend(slice_data),
        .subtrahend(slice_pattern),
        .difference(diff),
        .borrow_chain(borrow)
    );
    
    // Match if all differences are zero
    comparator #(
        .WIDTH(SLICE)
    ) zero_compare (
        .data(diff),
        .zero_pattern({SLICE{1'b0}}),
        .equal(match_out)
    );
endmodule

// Specialized module for conditional subtraction
module conditional_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference,
    output [WIDTH:0] borrow_chain
);
    // Calculation is done bit by bit with borrow propagation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = (~minuend[i] & subtrahend[i]) | 
                                       (borrow_chain[i] & (~(minuend[i] ^ subtrahend[i])));
        end
    endgenerate
endmodule

// Comparator module to check if input matches a pattern
module comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] zero_pattern,
    output equal
);
    assign equal = (data == zero_pattern);
endmodule

// Simple result selector based on control signal
module result_selector (
    input upper_match,
    input lower_match,
    input match_upper,
    output match_result
);
    // Select which result to output based on match_upper control
    assign match_result = match_upper ? upper_match : lower_match;
endmodule