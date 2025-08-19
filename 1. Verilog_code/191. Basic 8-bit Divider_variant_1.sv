//SystemVerilog
module divider_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Optimized divider implementation
    reg [7:0] partial_quotient;
    reg [7:0] partial_remainder;
    reg [7:0] scaled_divisor;
    reg [3:0] approx_reciprocal;
    reg [7:0] dividend_shifted;
    reg [7:0] divisor_shifted;
    reg [3:0] shift_count;
    
    // Optimized reciprocal lookup with range-based selection
    always @(*) begin
        // Handle division by zero
        if (divisor == 0) begin
            quotient = 8'hFF;
            remainder = dividend;
        end else begin
            // Normalize inputs by shifting
            shift_count = 0;
            dividend_shifted = dividend;
            divisor_shifted = divisor;
            
            while (divisor_shifted[7] == 0 && shift_count < 8) begin
                divisor_shifted = divisor_shifted << 1;
                dividend_shifted = dividend_shifted << 1;
                shift_count = shift_count + 1;
            end
            
            // Optimized reciprocal lookup using range checks
            if (divisor_shifted[7:4] <= 4'h1)
                approx_reciprocal = 4'hF;
            else if (divisor_shifted[7:4] <= 4'h2)
                approx_reciprocal = 4'h7;
            else if (divisor_shifted[7:4] <= 4'h4)
                approx_reciprocal = 4'h3;
            else if (divisor_shifted[7:4] <= 4'h7)
                approx_reciprocal = 4'h2;
            else
                approx_reciprocal = 4'h1;
            
            // Initial quotient estimation with optimized multiplication
            partial_quotient = (dividend_shifted[7:4] * approx_reciprocal) << 4;
            
            // Refined quotient calculation using binary search
            scaled_divisor = partial_quotient * divisor_shifted;
            
            if (scaled_divisor > dividend_shifted) begin
                partial_quotient = partial_quotient - 1;
                scaled_divisor = partial_quotient * divisor_shifted;
            end
            
            // Final remainder calculation
            partial_remainder = dividend_shifted - scaled_divisor;
            
            // Adjust results based on shift count
            quotient = partial_quotient >> shift_count;
            remainder = partial_remainder >> shift_count;
        end
    end

endmodule