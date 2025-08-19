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
    
    // Detect special cases
    wire a_is_zero = (a_exp == 8'h00) && (a_mant == 23'h0);
    wire b_is_zero = (b_exp == 8'h00) && (b_mant == 23'h0);
    wire a_is_inf = (a_exp == 8'hFF) && (a_mant == 23'h0);
    wire b_is_inf = (b_exp == 8'hFF) && (b_mant == 23'h0);
    wire a_is_nan = (a_exp == 8'hFF) && (a_mant != 23'h0);
    wire b_is_nan = (b_exp == 8'hFF) && (b_mant != 23'h0);
    
    // Comparison logic
    always @(*) begin
        // Default values
        eq_result = 1'b0;
        gt_result = 1'b0;
        lt_result = 1'b0;
        unordered = 1'b0;
        
        // Handle NaN cases
        if (a_is_nan || b_is_nan) begin
            unordered = 1'b1;
        end
        // Handle regular comparison cases
        else begin
            // Check for equality
            if (fp_a == fp_b || (a_is_zero && b_is_zero)) begin
                eq_result = 1'b1;
            end
            // Handle infinity cases
            else if (a_is_inf && b_is_inf) begin
                if (a_sign == b_sign)
                    eq_result = 1'b1;
                else if (a_sign)
                    lt_result = 1'b1;
                else
                    gt_result = 1'b1;
            end
            // Handle cases with different signs
            else if (a_sign != b_sign) begin
                if (a_sign)
                    lt_result = 1'b1;
                else
                    gt_result = 1'b1;
            end
            // Handle positive cases (both have same sign)
            else if (!a_sign) begin
                if (a_exp > b_exp || (a_exp == b_exp && a_mant > b_mant))
                    gt_result = 1'b1;
                else
                    lt_result = 1'b1;
            end
            // Handle negative cases (both have same sign)
            else begin
                if (a_exp > b_exp || (a_exp == b_exp && a_mant > b_mant))
                    lt_result = 1'b1;
                else
                    gt_result = 1'b1;
            end
        end
    end
endmodule