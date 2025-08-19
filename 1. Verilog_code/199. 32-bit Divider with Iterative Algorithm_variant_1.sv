//SystemVerilog
module divider_iterative_32bit (
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

always @(*) begin
    quotient = 0;
    remainder = dividend;

    // Optimize the comparison and subtraction using a more efficient approach
    if (divisor != 0) begin
        // Use a range check and optimized comparison logic
        for (integer i = 31; i >= 0; i = i - 1) begin
            // Check if the shifted remainder can accommodate the divisor
            if (remainder >= (divisor << i)) begin
                remainder = remainder - (divisor << i);
                quotient = quotient | (1 << i);
            end
        end
    end
end

endmodule