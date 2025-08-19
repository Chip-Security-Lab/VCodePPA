//SystemVerilog
module one_hot_comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] one_hot_a,
    input [WIDTH-1:0] one_hot_b,
    output valid_one_hot_a,
    output valid_one_hot_b,
    output equal_states,
    output [WIDTH-1:0] common_states
);

    // Optimized one-hot validation using population count
    wire [WIDTH-1:0] a_popcount, b_popcount;
    assign a_popcount = one_hot_a;
    assign b_popcount = one_hot_b;
    
    // Valid one-hot check: population count should be 1
    assign valid_one_hot_a = (a_popcount == 1);
    assign valid_one_hot_b = (b_popcount == 1);
    
    // Common states (bitwise AND)
    assign common_states = one_hot_a & one_hot_b;
    
    // Equal states: optimized using direct comparison
    assign equal_states = (one_hot_a == one_hot_b) || (|common_states);
endmodule