//SystemVerilog
module async_pattern_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in, pattern,
    output match_out
);
    wire [WIDTH-1:0] subtraction_result;
    wire borrow_out;
    
    // Conditional inverse subtractor implementation
    // A - B = A + ~B + 1 (Two's complement method)
    wire [WIDTH-1:0] inverted_pattern;
    wire [WIDTH:0] temp_sum; // Extra bit for carry
    
    // Invert pattern for subtraction
    assign inverted_pattern = ~pattern;
    
    // Perform addition with inverted pattern and add 1 (two's complement)
    assign temp_sum = data_in + inverted_pattern + 1'b1;
    
    // Extract result and borrow
    assign subtraction_result = temp_sum[WIDTH-1:0];
    assign borrow_out = ~temp_sum[WIDTH];
    
    // If result is zero (all bits are 0), then there's a match
    assign match_out = (subtraction_result == {WIDTH{1'b0}});
endmodule