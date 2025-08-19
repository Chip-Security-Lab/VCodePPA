//SystemVerilog
module fp_comparator(
    input [31:0] fp_a,      // IEEE 754 single precision format
    input [31:0] fp_b,      // IEEE 754 single precision format
    output reg eq_result,   // Equal
    output reg gt_result,   // Greater than
    output reg lt_result,   // Less than
    output reg unordered    // True when either input is NaN
);
    // Extract sign, exponent, and mantissa fields
    wire a_sign = fp_a[31];
    wire b_sign = fp_b[31];
    wire [7:0] a_exp = fp_a[30:23];
    wire [7:0] b_exp = fp_b[30:23];
    wire [22:0] a_mant = fp_a[22:0];
    wire [22:0] b_mant = fp_b[22:0];
    
    // Detect special cases with optimized logic
    wire a_is_zero = ~|{a_exp, a_mant};
    wire b_is_zero = ~|{b_exp, b_mant};
    wire both_zero = a_is_zero & b_is_zero;
    
    wire a_exp_max = &a_exp;
    wire b_exp_max = &b_exp;
    wire a_mant_zero = ~|a_mant;
    wire b_mant_zero = ~|b_mant;
    
    wire a_is_inf = a_exp_max & a_mant_zero;
    wire b_is_inf = b_exp_max & b_mant_zero;
    wire a_is_nan = a_exp_max & ~a_mant_zero;
    wire b_is_nan = b_exp_max & ~b_mant_zero;
    
    // Fast equality check
    wire exact_equal = (fp_a == fp_b);
    
    // Pre-compute magnitude comparison
    wire a_mag_gt_b = (a_exp > b_exp) | ((a_exp == b_exp) & (a_mant > b_mant));
    
    // Optimized comparison logic with parallel evaluation
    always @(*) begin
        // Set defaults to avoid latches
        unordered = a_is_nan | b_is_nan;
        
        if (unordered) begin
            eq_result = 1'b0;
            gt_result = 1'b0;
            lt_result = 1'b0;
        end
        else if (exact_equal | both_zero) begin
            eq_result = 1'b1;
            gt_result = 1'b0;
            lt_result = 1'b0;
        end
        else if (a_sign ^ b_sign) begin
            // Different signs
            eq_result = 1'b0;
            gt_result = ~a_sign;
            lt_result = a_sign;
        end
        else begin
            // Same sign - magnitude determines result
            eq_result = 1'b0;
            
            if (a_sign == 1'b0) begin // Both positive
                gt_result = a_mag_gt_b;
                lt_result = ~a_mag_gt_b;
            end
            else begin // Both negative (a_sign == 1'b1)
                gt_result = ~a_mag_gt_b;
                lt_result = a_mag_gt_b;
            end
        end
        
        // Handle infinity cases - overrides previous results
        if (a_is_inf & b_is_inf) begin
            if (a_sign == b_sign) begin
                eq_result = 1'b1;
                gt_result = 1'b0;
                lt_result = 1'b0;
            end
        end
    end
endmodule