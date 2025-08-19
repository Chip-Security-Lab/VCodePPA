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
    // Check if inputs are valid one-hot encoded (exactly one bit set)
    // 使用计数方法代替$countones
    wire [WIDTH:0] popcount_a;
    wire [WIDTH:0] popcount_b;
    assign popcount_a[0] = 0;
    assign popcount_b[0] = 0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : popcount_gen
            assign popcount_a[i+1] = popcount_a[i] + one_hot_a[i];
            assign popcount_b[i+1] = popcount_b[i] + one_hot_b[i];
        end
    endgenerate
    
    assign valid_one_hot_a = (popcount_a[WIDTH] == 1);
    assign valid_one_hot_b = (popcount_b[WIDTH] == 1);
    
    // Common states (bitwise AND)
    assign common_states = one_hot_a & one_hot_b;
    
    // Equal states - either they are the same or they have common set bits
    assign equal_states = (one_hot_a == one_hot_b) || (|common_states);
endmodule