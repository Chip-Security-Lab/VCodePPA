//SystemVerilog
module window_comparator(
    input [11:0] data_value,
    input [11:0] lower_bound,
    input [11:0] upper_bound,
    output in_range,         // High when lower_bound ≤ data_value ≤ upper_bound
    output out_of_range,     // High when data_value < lower_bound OR data_value > upper_bound
    output at_boundary       // High when data_value equals either bound
);
    // Instantiate boundary comparison module
    boundary_comparator boundary_comp(
        .data_value(data_value),
        .lower_bound(lower_bound),
        .upper_bound(upper_bound),
        .below_lower(below_lower),
        .above_upper(above_upper),
        .equal_lower(equal_lower),
        .equal_upper(equal_upper)
    );
    
    // Instantiate range evaluation module
    range_evaluator range_eval(
        .below_lower(below_lower),
        .above_upper(above_upper),
        .equal_lower(equal_lower),
        .equal_upper(equal_upper),
        .in_range(in_range),
        .out_of_range(out_of_range),
        .at_boundary(at_boundary)
    );
endmodule

// Module for comparing data value with boundaries
module boundary_comparator(
    input [11:0] data_value,
    input [11:0] lower_bound,
    input [11:0] upper_bound,
    output below_lower,
    output above_upper,
    output equal_lower,
    output equal_upper
);
    // Range comparisons
    assign below_lower = (data_value < lower_bound);
    assign above_upper = (data_value > upper_bound);
    assign equal_lower = (data_value == lower_bound);
    assign equal_upper = (data_value == upper_bound);
endmodule

// Module for evaluating range conditions
module range_evaluator(
    input below_lower,
    input above_upper,
    input equal_lower,
    input equal_upper,
    output in_range,
    output out_of_range,
    output at_boundary
);
    // Output assignments
    assign in_range = !(below_lower || above_upper);
    assign out_of_range = below_lower || above_upper;
    assign at_boundary = equal_lower || equal_upper;
endmodule