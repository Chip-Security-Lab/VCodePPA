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
    
    // Calculate absolute difference using borrow subtractor
    wire [WIDTH-1:0] difference;
    wire [WIDTH-1:0] minuend, subtrahend;
    wire subtraction_direction;
    wire [WIDTH-1:0] borrow;
    
    // Determine operation direction based on which value is larger
    assign subtraction_direction = (value_a < value_b);
    
    // Select minuend and subtrahend based on direction
    assign minuend = subtraction_direction ? value_b : value_a;
    assign subtrahend = subtraction_direction ? value_a : value_b;
    
    // Implement borrow subtractor
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow
            if (i == 0) begin: first_bit
                assign borrow[i] = (minuend[i] < subtrahend[i]);
                assign difference[i] = minuend[i] ^ subtrahend[i];
            end else begin: other_bits
                assign borrow[i] = (minuend[i] < subtrahend[i]) || 
                                   ((minuend[i] == subtrahend[i]) && borrow[i-1]);
                assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i-1];
            end
        end
    endgenerate
    
    // Check if within tolerance
    assign approximate_match = (difference <= effective_tolerance);
endmodule