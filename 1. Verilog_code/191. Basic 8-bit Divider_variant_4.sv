//SystemVerilog
module divider_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient,
    output [7:0] remainder
);

    wire [7:0] div_quotient;
    wire [7:0] div_remainder;

    // Instantiate the lookup table based divider
    lut_divider lut_div_inst (
        .dividend(dividend),
        .divisor(divisor),
        .quotient(div_quotient),
        .remainder(div_remainder)
    );

    // Assign outputs from the LUT divider
    assign quotient = div_quotient;
    assign remainder = div_remainder;

endmodule

module lut_divider (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] lookup_table [0:255]; // Lookup table for quotients

    initial begin
        // Populate the lookup table
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 1; j < 256; j = j + 1) begin
                if (j != 0) begin
                    lookup_table[i] = i / j; // Store quotient
                end
            end
        end
    end

    always @(*) begin
        if (divisor != 0) begin
            quotient = lookup_table[dividend]; // Get quotient from lookup table
            remainder = dividend - (quotient * divisor); // Calculate remainder
        end else begin
            quotient = 8'b0; // Handle division by zero
            remainder = dividend; // Remainder is the dividend
        end
    end

endmodule