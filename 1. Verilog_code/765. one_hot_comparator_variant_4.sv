//SystemVerilog
module one_hot_comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] one_hot_a,     // One-hot encoded input A
    input [WIDTH-1:0] one_hot_b,     // One-hot encoded input B
    output valid_one_hot_a,          // Checks if A is valid one-hot
    output valid_one_hot_b,          // Checks if B is valid one-hot
    output equal_states,             // True if both represent the same state
    output [WIDTH-1:0] common_states // Bitwise AND showing common active bits
);
    // LUT-based subtractor implementation for one-hot validation
    // Lookup table for subtraction results
    reg [WIDTH-1:0] lut_sub_results [0:255];
    reg [WIDTH-1:0] borrow_lut [0:255];
    
    // LUT-based subtraction: a - 1
    wire [WIDTH-1:0] result_a;
    wire [WIDTH-1:0] borrow_result_a;
    
    // LUT-based subtraction: b - 1
    wire [WIDTH-1:0] result_b;
    wire [WIDTH-1:0] borrow_result_b;
    
    // Initialize lookup tables (would be pre-calculated in synthesis)
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_sub_results[i] = i - 1;
            borrow_lut[i] = (i < 1) ? 8'h01 : 8'h00;
        end
    end
    
    // Get subtraction results from LUT
    assign result_a = lut_sub_results[one_hot_a];
    assign borrow_result_a = borrow_lut[one_hot_a];
    
    assign result_b = lut_sub_results[one_hot_b];
    assign borrow_result_b = borrow_lut[one_hot_b];
    
    // Validate one-hot encoding using LUT-based subtraction results
    wire at_most_one_bit_a = ((one_hot_a & result_a) == 0);
    wire at_most_one_bit_b = ((one_hot_b & result_b) == 0);
    wire at_least_one_bit_a = |one_hot_a;
    wire at_least_one_bit_b = |one_hot_b;
    
    assign valid_one_hot_a = at_most_one_bit_a & at_least_one_bit_a;
    assign valid_one_hot_b = at_most_one_bit_b & at_least_one_bit_b;
    
    // Common states (bitwise AND)
    assign common_states = one_hot_a & one_hot_b;
    
    // Equal states check
    wire has_common_bits = |common_states;
    assign equal_states = has_common_bits;
endmodule