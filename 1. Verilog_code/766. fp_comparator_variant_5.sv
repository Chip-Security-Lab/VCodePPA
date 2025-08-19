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
    
    // Detect special cases
    wire a_is_zero = (a_exp == 8'h00) && (a_mant == 23'h0);
    wire b_is_zero = (b_exp == 8'h00) && (b_mant == 23'h0);
    wire a_is_inf = (a_exp == 8'hFF) && (a_mant == 23'h0);
    wire b_is_inf = (b_exp == 8'hFF) && (b_mant == 23'h0);
    wire a_is_nan = (a_exp == 8'hFF) && (a_mant != 23'h0);
    wire b_is_nan = (b_exp == 8'hFF) && (a_mant != 23'h0);
    
    // Intermediate comparison results
    wire same_sign = (a_sign == b_sign);
    wire exp_gt = (a_exp > b_exp);
    wire exp_eq = (a_exp == b_exp);
    wire mant_gt = (a_mant > b_mant);
    wire both_inf = a_is_inf && b_is_inf;
    wire both_zero = a_is_zero && b_is_zero;
    
    // Handle NaN cases
    always @(*) begin
        unordered = a_is_nan || b_is_nan;
    end
    
    // Handle equality cases
    always @(*) begin
        eq_result = (fp_a == fp_b) || both_zero || (both_inf && same_sign);
    end
    
    // Handle greater than cases
    always @(*) begin
        gt_result = 1'b0;
        
        if (!unordered && !both_inf && !both_zero) begin
            if (!a_sign && b_sign) begin
                gt_result = 1'b1;
            end
            else if (same_sign && !a_sign) begin
                gt_result = exp_gt || (exp_eq && mant_gt);
            end
            else if (same_sign && a_sign) begin
                gt_result = !exp_gt && !(exp_eq && mant_gt);
            end
        end
    end
    
    // Handle less than cases
    always @(*) begin
        lt_result = 1'b0;
        
        if (!unordered && !both_inf && !both_zero) begin
            if (a_sign && !b_sign) begin
                lt_result = 1'b1;
            end
            else if (same_sign && !a_sign) begin
                lt_result = !exp_gt && !(exp_eq && mant_gt);
            end
            else if (same_sign && a_sign) begin
                lt_result = exp_gt || (exp_eq && mant_gt);
            end
        end
    end
endmodule