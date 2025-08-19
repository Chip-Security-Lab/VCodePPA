//SystemVerilog
// Top-level module: Hierarchical BCD to Binary Converter
module bcd_to_binary #(
    parameter DIGITS = 3
)(
    input  wire [4*DIGITS-1:0] bcd_in,
    output wire [DIGITS*3+3:0] binary_out
);

    // Internal signal for digit extraction
    wire [3:0] bcd_digit [0:DIGITS-1];
    // Internal signal for binary accumulation
    wire [DIGITS*3+3:0] binary_sum;

    genvar idx;
    // Digit Extraction: Extract each BCD digit from input vector
    generate
        for (idx = 0; idx < DIGITS; idx = idx + 1) begin : BCD_EXTRACT
            assign bcd_digit[idx] = bcd_in[4*idx+3 -: 4];
        end
    endgenerate

    // Accumulator: Converts BCD digits to binary
    bcd_accumulator #(
        .DIGITS(DIGITS)
    ) u_bcd_accumulator (
        .bcd_digits   (bcd_digit),
        .binary_value (binary_sum)
    );

    assign binary_out = binary_sum;

endmodule

// -----------------------------------------------------------------------------
// Submodule: BCD Accumulator
// Description: Accumulates BCD digits into a binary value using base-10 weighting
// -----------------------------------------------------------------------------
module bcd_accumulator #(
    parameter DIGITS = 3
)(
    input  wire [3:0] bcd_digits [0:DIGITS-1],
    output reg  [DIGITS*3+3:0] binary_value
);
    integer i;
    reg [DIGITS*3+3:0] result;
    reg [DIGITS*3+3:0] mult_ten;

    always @* begin
        result = 0;
        mult_ten = 1;
        for (i = DIGITS-1; i >= 0; i = i - 1) begin
            result = result + bcd_digits[i] * mult_ten;
            mult_ten = mult_ten * 10;
        end
        binary_value = result;
    end
endmodule