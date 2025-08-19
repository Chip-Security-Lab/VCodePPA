//SystemVerilog
// Hierarchical sign-magnitude conversion module

// -----------------------------------------------------------------------------
// Top-level module: signmag_conv
// Performs sign-magnitude conversion using hierarchical submodules.
// -----------------------------------------------------------------------------
module signmag_conv (
    input  signed [15:0] in_data,
    output        [15:0] out_data
);

    wire        sign_bit;
    wire [14:0] magnitude_bits;
    wire [14:0] abs_magnitude_bits;

    // Extract sign and magnitude
    signmag_extract u_signmag_extract (
        .input_word    (in_data),
        .sign_out      (sign_bit),
        .magnitude_out (magnitude_bits)
    );

    // Compute absolute value of magnitude
    signmag_abs u_signmag_abs (
        .sign_in          (sign_bit),
        .magnitude_in     (magnitude_bits),
        .abs_magnitude_out(abs_magnitude_bits)
    );

    // Combine sign and absolute magnitude to form output word
    signmag_combine u_signmag_combine (
        .sign_in          (sign_bit),
        .magnitude_in     (abs_magnitude_bits),
        .output_word      (out_data)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: signmag_extract
// Purpose: Extracts the sign bit and magnitude from the input 16-bit word.
// -----------------------------------------------------------------------------
module signmag_extract (
    input  signed [15:0] input_word,
    output               sign_out,
    output        [14:0] magnitude_out
);
    assign sign_out      = input_word[15];
    assign magnitude_out = input_word[14:0];
endmodule

// -----------------------------------------------------------------------------
// Submodule: signmag_abs
// Purpose: Computes the absolute value of the magnitude based on the sign bit.
// If sign is 1, inverts the magnitude (two's complement form).
// -----------------------------------------------------------------------------
module signmag_abs (
    input        sign_in,
    input  [14:0] magnitude_in,
    output [14:0] abs_magnitude_out
);
    assign abs_magnitude_out = sign_in ? (~magnitude_in + 1'b1) : magnitude_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: signmag_combine
// Purpose: Combines sign bit and magnitude into a single 16-bit word.
// -----------------------------------------------------------------------------
module signmag_combine (
    input        sign_in,
    input  [14:0] magnitude_in,
    output [15:0] output_word
);
    assign output_word = {sign_in, magnitude_in};
endmodule