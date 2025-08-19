module bcd_comparator(
    input [3:0] bcd_digit_a,  // BCD digit (0-9)
    input [3:0] bcd_digit_b,  // BCD digit (0-9)
    output reg equal,         // A equals B
    output reg greater,       // A greater than B
    output reg less,          // A less than B
    output reg invalid_bcd    // High if either input is not a valid BCD digit
);
    // BCD validity check
    wire valid_a = (bcd_digit_a <= 4'd9);
    wire valid_b = (bcd_digit_b <= 4'd9);
    
    always @(*) begin
        // Check if inputs are valid BCD digits
        invalid_bcd = !valid_a || !valid_b;
        
        // Default values
        equal = 1'b0;
        greater = 1'b0;
        less = 1'b0;
        
        if (valid_a && valid_b) begin
            // Valid BCD comparison
            if (bcd_digit_a == bcd_digit_b)
                equal = 1'b1;
            else if (bcd_digit_a > bcd_digit_b)
                greater = 1'b1;
            else
                less = 1'b1;
        end
    end
endmodule