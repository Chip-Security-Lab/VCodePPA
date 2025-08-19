//SystemVerilog

// Top-level module
module divider_iterative_32bit (
    input [31:0] dividend,
    input [31:0] divisor,
    output [31:0] quotient,
    output [31:0] remainder
);

    wire [31:0] temp_quotient;
    wire [31:0] temp_remainder;

    // Instantiate the quotient and remainder calculation module
    quotient_remainder_calculator calc (
        .dividend(dividend),
        .divisor(divisor),
        .quotient(temp_quotient),
        .remainder(temp_remainder)
    );

    // Assign outputs
    assign quotient = temp_quotient;
    assign remainder = temp_remainder;

endmodule

// Submodule for calculating quotient and remainder
module quotient_remainder_calculator (
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

    reg [31:0] temp_remainder;
    reg [31:0] temp_quotient;
    reg [31:0] shifted_divisor;
    integer i;

    always @(*) begin
        temp_remainder = dividend;
        temp_quotient = 0;
        
        for (i = 31; i >= 0; i = i - 1) begin
            shifted_divisor = divisor << i;
            if (temp_remainder >= shifted_divisor) begin
                temp_remainder = temp_remainder - shifted_divisor;
                temp_quotient = temp_quotient | (1 << i);
            end
        end
        
        quotient = temp_quotient;
        remainder = temp_remainder;
    end

endmodule