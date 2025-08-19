module approximate_comparator #(
    parameter WIDTH = 12,
    parameter TOLERANCE = 3  // Default tolerance of ±3
)(
    input [WIDTH-1:0] value_a,
    input [WIDTH-1:0] value_b,
    input [WIDTH-1:0] custom_tolerance, // Optional custom tolerance value
    input use_custom_tolerance,         // Use custom tolerance instead of parameter
    output approximate_match            // High when values are within tolerance
);
    // Determine which tolerance to use
    wire [WIDTH-1:0] effective_tolerance;
    assign effective_tolerance = use_custom_tolerance ? custom_tolerance : TOLERANCE;
    
    // Calculate absolute difference
    wire [WIDTH-1:0] difference;
    assign difference = (value_a > value_b) ? (value_a - value_b) : (value_b - value_a);
    
    // Check if within tolerance
    assign approximate_match = (difference <= effective_tolerance);
endmodule