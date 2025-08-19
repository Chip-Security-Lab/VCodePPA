module mode_selectable_comparator(
    input [15:0] input_a,
    input [15:0] input_b,
    input signed_mode,  // 0=unsigned, 1=signed comparison
    output is_equal,
    output is_greater,
    output is_less
);
    // Internal wires for comparison results
    wire unsigned_gt, unsigned_eq, unsigned_lt;
    wire signed_gt, signed_eq, signed_lt;
    
    // Unsigned comparison
    assign unsigned_eq = (input_a == input_b);
    assign unsigned_gt = (input_a > input_b);
    assign unsigned_lt = (input_a < input_b);
    
    // Signed comparison (requires type casting)
    assign signed_eq = (input_a == input_b);
    assign signed_gt = ($signed(input_a) > $signed(input_b));
    assign signed_lt = ($signed(input_a) < $signed(input_b));
    
    // Select the appropriate comparison result based on mode
    assign is_equal = signed_mode ? signed_eq : unsigned_eq;
    assign is_greater = signed_mode ? signed_gt : unsigned_gt;
    assign is_less = signed_mode ? signed_lt : unsigned_lt;
endmodule