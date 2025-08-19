//SystemVerilog
module simple_4bit_divider (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);

    // Division core module
    div_core div_core_inst (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// Optimized division core implementation
module div_core (
    input [3:0] dividend,
    input [3:0] divisor,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    // Internal signals for optimized division
    reg [3:0] temp_quotient;
    reg [3:0] temp_remainder;
    reg [3:0] shifted_divisor;
    reg [3:0] count;
    reg [3:0] dividend_copy;
    
    always @(*) begin
        // Handle division by zero case
        if (divisor == 4'b0) begin
            quotient = 4'b0;
            remainder = 4'b0;
        end else begin
            // Initialize variables
            temp_quotient = 4'b0;
            temp_remainder = 4'b0;
            dividend_copy = dividend;
            shifted_divisor = divisor;
            
            // Binary division algorithm implementation
            for (count = 0; count < 4; count = count + 1) begin
                // Shift left the remainder and add MSB of dividend
                temp_remainder = {temp_remainder[2:0], dividend_copy[3]};
                dividend_copy = {dividend_copy[2:0], 1'b0};
                
                // Compare and subtract if possible
                if (temp_remainder >= shifted_divisor) begin
                    temp_remainder = temp_remainder - shifted_divisor;
                    temp_quotient[3-count] = 1'b1;
                end else begin
                    temp_quotient[3-count] = 1'b0;
                end
            end
            
            // Assign final results
            quotient = temp_quotient;
            remainder = temp_remainder;
        end
    end

endmodule