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
    wire b_is_nan = (b_exp == 8'hFF) && (b_mant != 23'h0);
    
    // Magnitude comparison
    wire a_mag_gt_b = (a_exp > b_exp) || ((a_exp == b_exp) && (a_mant > b_mant));
    wire exactly_equal = (fp_a == fp_b) || (a_is_zero && b_is_zero);
    
    // Encode comparison conditions
    reg [4:0] compare_state;
    
    always @(*) begin
        // Default values
        eq_result = 1'b0;
        gt_result = 1'b0;
        lt_result = 1'b0;
        unordered = 1'b0;
        
        // Encode state: {NaN_case, exact_equal, diff_signs, both_inf, a_mag_gt_b}
        compare_state = {
            (a_is_nan || b_is_nan),
            exactly_equal,
            (a_sign != b_sign),
            (a_is_inf && b_is_inf),
            a_mag_gt_b
        };
        
        case (compare_state)
            // NaN case (highest priority)
            5'b1????: begin
                unordered = 1'b1;
            end
            
            // Exact equality
            5'b01???: begin
                eq_result = 1'b1;
            end
            
            // Both infinity with same sign
            5'b001?0: begin
                if (a_sign == b_sign)
                    eq_result = 1'b1;
                else if (a_sign)
                    lt_result = 1'b1;
                else
                    gt_result = 1'b1;
            end
            
            // Different signs
            5'b0010?: begin
                if (a_sign)
                    lt_result = 1'b1;
                else
                    gt_result = 1'b1;
            end
            
            // Same sign, positive
            5'b0001?: begin
                if (!a_sign) begin
                    if (a_mag_gt_b)
                        gt_result = 1'b1;
                    else
                        lt_result = 1'b1;
                end else begin
                    if (a_mag_gt_b)
                        lt_result = 1'b1;
                    else
                        gt_result = 1'b1;
                end
            end
            
            // Same sign, negative
            5'b00001: begin
                if (a_sign)
                    lt_result = 1'b1;
                else
                    gt_result = 1'b1;
            end
            
            5'b00000: begin
                if (a_sign)
                    gt_result = 1'b1;
                else
                    lt_result = 1'b1;
            end
            
            default: begin
                // Should never reach here
                eq_result = 1'b0;
                gt_result = 1'b0;
                lt_result = 1'b0;
                unordered = 1'b0;
            end
        endcase
    end
endmodule