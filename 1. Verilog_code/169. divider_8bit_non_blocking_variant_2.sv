//SystemVerilog
module divider_8bit_non_blocking (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [15:0] dividend; // 16-bit dividend to hold a
    reg [7:0] divisor;   // 8-bit divisor to hold b
    reg [7:0] temp_quotient; // Intermediate quotient
    reg [15:0] temp_remainder; // Intermediate remainder
    integer i;

    always @(*) begin
        dividend = {8'b0, a}; // Extend a to 16 bits
        divisor = b;
        temp_quotient = 0;
        temp_remainder = 0;

        for (i = 7; i >= 0; i = i - 1) begin
            temp_remainder = {temp_remainder[14:0], dividend[15]}; // Shift left
            dividend = {dividend[14:0], 1'b0}; // Shift dividend left
            if (temp_remainder >= divisor) begin
                temp_remainder = temp_remainder - divisor; // Subtract divisor
                temp_quotient[i] = 1; // Set quotient bit
            end
        end

        quotient = temp_quotient;
        remainder = temp_remainder[7:0]; // Take the lower 8 bits as remainder
    end
endmodule