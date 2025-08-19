//SystemVerilog
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
    
    // Calculate absolute difference using carry-lookahead subtraction
    wire [WIDTH-1:0] difference;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] a_minus_b;
    wire [WIDTH-1:0] b_minus_a;
    
    // Generate borrow signals
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i] = (value_a[i] < value_b[i]) ? 1'b1 : 1'b0;
        end
    endgenerate
    
    // Carry lookahead logic
    assign carry[0] = 1'b0;
    genvar j;
    generate
        for(j = 0; j < WIDTH; j = j + 1) begin : gen_carry
            assign carry[j+1] = borrow[j] | (carry[j] & (value_a[j] == value_b[j]));
        end
    endgenerate
    
    // Calculate both possible differences
    genvar k;
    generate
        for(k = 0; k < WIDTH; k = k + 1) begin : gen_diff
            assign a_minus_b[k] = value_a[k] ^ value_b[k] ^ carry[k];
            assign b_minus_a[k] = value_b[k] ^ value_a[k] ^ carry[k];
        end
    endgenerate
    
    // Select correct difference based on comparison
    assign difference = (value_a > value_b) ? a_minus_b : b_minus_a;
    
    // Check if within tolerance
    assign approximate_match = (difference <= effective_tolerance);

endmodule