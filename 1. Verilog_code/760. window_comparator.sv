module window_comparator(
    input [11:0] data_value,
    input [11:0] lower_bound,
    input [11:0] upper_bound,
    output in_range,         // High when lower_bound ≤ data_value ≤ upper_bound
    output out_of_range,     // High when data_value < lower_bound OR data_value > upper_bound
    output at_boundary       // High when data_value equals either bound
);
    // Range comparisons
    wire below_lower = (data_value < lower_bound);
    wire above_upper = (data_value > upper_bound);
    wire equal_lower = (data_value == lower_bound);
    wire equal_upper = (data_value == upper_bound);
    
    // Output assignments
    assign in_range = !(below_lower || above_upper);
    assign out_of_range = below_lower || above_upper;
    assign at_boundary = equal_lower || equal_upper;
endmodule