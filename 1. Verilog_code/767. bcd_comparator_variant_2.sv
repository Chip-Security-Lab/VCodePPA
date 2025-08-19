//SystemVerilog
module bcd_comparator(
    input [3:0] bcd_digit_a,  // BCD digit (0-9)
    input [3:0] bcd_digit_b,  // BCD digit (0-9)
    output equal,             // A equals B
    output greater,           // A greater than B
    output less,              // A less than B
    output invalid_bcd        // High if either input is not a valid BCD digit
);
    // BCD validity check - optimized expressions
    wire valid_a = ~bcd_digit_a[3] & ~(bcd_digit_a[2] & bcd_digit_a[1]);
    wire valid_b = ~bcd_digit_b[3] & ~(bcd_digit_b[2] & bcd_digit_b[1]);
    
    // Final validity signal (simplified)
    assign invalid_bcd = ~valid_a | ~valid_b;
    
    // Comparison logic (optimized)
    wire [3:0] diff = bcd_digit_a - bcd_digit_b;
    wire is_equal = ~|diff;
    wire is_greater = ~diff[3] & |diff;
    
    // Masked outputs with reduced logic depth
    assign equal = is_equal & valid_a & valid_b;
    assign greater = is_greater & valid_a & valid_b;
    assign less = (~is_equal & ~is_greater) & valid_a & valid_b;
    
endmodule