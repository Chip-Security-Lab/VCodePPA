//SystemVerilog
// Top-level module: Hierarchical BCD to Binary Converter
module bcd_to_binary #(
    parameter DIGITS = 3
)(
    input  wire [4*DIGITS-1:0] bcd_in,
    output wire [DIGITS*3+3:0] binary_out
);

    // Internal signals for extracted BCD digits
    wire [3:0] bcd_digits [0:DIGITS-1];

    // Internal wire for binary output from core
    wire [DIGITS*3+3:0] binary_value;

    // Extract BCD digits from input vector using digit extractor submodules
    genvar idx;
    generate
        for (idx = 0; idx < DIGITS; idx = idx + 1) begin : extract_bcd_digits
            // BCD Digit Extractor Submodule
            bcd_digit_extractor u_bcd_digit_extractor (
                .bcd_vector_in(bcd_in),
                .digit_index(idx),
                .bcd_digit_out(bcd_digits[idx])
            );
        end
    endgenerate

    // Instantiate the BCD to Binary core conversion module
    bcd_to_binary_core #(
        .DIGITS(DIGITS)
    ) u_bcd_to_binary_core (
        .bcd_digits_in(bcd_digits),
        .binary_out(binary_value)
    );

    // Output assignment
    assign binary_out = binary_value;

endmodule

// -----------------------------------------------------------------------------
// Submodule: BCD Digit Extractor
// Extracts a single BCD digit from a packed BCD input vector.
// -----------------------------------------------------------------------------
module bcd_digit_extractor #(
    parameter DIGITS = 3
)(
    input  wire [4*DIGITS-1:0] bcd_vector_in,
    input  wire [$clog2(DIGITS)-1:0] digit_index,
    output wire [3:0] bcd_digit_out
);
    assign bcd_digit_out = bcd_vector_in[4*digit_index+3 -: 4];
endmodule

// -----------------------------------------------------------------------------
// Submodule: BCD to Binary Core Conversion
// Performs the conversion of a BCD digit array to a binary number.
// -----------------------------------------------------------------------------
module bcd_to_binary_core #(
    parameter DIGITS = 3
)(
    input  wire [3:0] bcd_digits_in [0:DIGITS-1],
    output wire [DIGITS*3+3:0] binary_out
);

    // Internal signals for staged multiplication and accumulation
    wire [DIGITS*3+3:0] stage_sum [0:DIGITS];

    assign stage_sum[0] = { (DIGITS*3+4){1'b0} };

    genvar i;
    generate
        for (i = 0; i < DIGITS; i = i + 1) begin : bcd_accumulate
            bcd_digit_accumulator #(
                .WIDTH(DIGITS*3+4)
            ) u_bcd_digit_accumulator (
                .acc_in(stage_sum[i]),
                .bcd_digit_in(bcd_digits_in[i]),
                .acc_out(stage_sum[i+1])
            );
        end
    endgenerate

    assign binary_out = stage_sum[DIGITS];

endmodule

// -----------------------------------------------------------------------------
// Submodule: BCD Digit Accumulator
// Multiplies the accumulator by 10 and adds the next BCD digit.
// -----------------------------------------------------------------------------
module bcd_digit_accumulator #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] acc_in,
    input  wire [3:0] bcd_digit_in,
    output wire [WIDTH-1:0] acc_out
);
    assign acc_out = acc_in * 10 + bcd_digit_in;
endmodule