//SystemVerilog
module divider_iterative_32bit (
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

reg [31:0] temp_remainder;
reg [31:0] temp_quotient;
integer i;

// Optimized iterative division
always @(*) begin
    temp_quotient = 0;
    temp_remainder = dividend;

    for (i = 31; i >= 0; i = i - 1) begin
        temp_remainder = {temp_remainder[30:0], 1'b0}; // Shift left
        if (temp_remainder >= divisor) begin
            temp_remainder = temp_remainder - divisor; // Subtract divisor
            temp_quotient[i] = 1'b1; // Set quotient bit
        end else begin
            temp_quotient[i] = 1'b0; // Clear quotient bit
        end
    end

    quotient = temp_quotient;
    remainder = temp_remainder;
end

endmodule