//SystemVerilog
// Top-level module: Sign-magnitude converter (Hierarchical, modular structure)
module signmag_conv(
    input  signed [15:0] in,
    output        [15:0] out
);

    // Internal signals for sign and magnitude processing
    wire                sign_bit;
    wire        [14:0]  magnitude;
    wire        [14:0]  processed_magnitude;

    // Instance: Sign and Magnitude Extraction
    signmag_sign_extract u_sign_extract (
        .din        (in),
        .sign_bit   (sign_bit),
        .magnitude  (magnitude)
    );

    // Instance: Magnitude Processing (Conditional inversion)
    signmag_magnitude_process u_magnitude_process (
        .sign_bit       (sign_bit),
        .magnitude_in   (magnitude),
        .magnitude_out  (processed_magnitude)
    );

    // Instance: Output Composition
    signmag_output_composer u_output_composer (
        .sign_bit       (sign_bit),
        .magnitude_in   (processed_magnitude),
        .dout           (out)
    );

endmodule

// -----------------------------------------------------------------------------
// Module: signmag_sign_extract
// Function: Extracts the sign bit and magnitude bits from a 16-bit signed input
// -----------------------------------------------------------------------------
module signmag_sign_extract (
    input  signed [15:0] din,
    output               sign_bit,
    output        [14:0] magnitude
);
    assign sign_bit  = din[15];
    assign magnitude = din[14:0];
endmodule

// -----------------------------------------------------------------------------
// Module: signmag_magnitude_process
// Function: Conditionally inverts the magnitude bits based on the sign bit
// -----------------------------------------------------------------------------
module signmag_magnitude_process (
    input         sign_bit,
    input  [14:0] magnitude_in,
    output [14:0] magnitude_out
);
    assign magnitude_out = magnitude_in ^ {15{sign_bit}};
endmodule

// -----------------------------------------------------------------------------
// Module: signmag_output_composer
// Function: Composes the sign bit and processed magnitude into the output
// -----------------------------------------------------------------------------
module signmag_output_composer (
    input        sign_bit,
    input [14:0] magnitude_in,
    output [15:0] dout
);
    assign dout = {sign_bit, magnitude_in};
endmodule