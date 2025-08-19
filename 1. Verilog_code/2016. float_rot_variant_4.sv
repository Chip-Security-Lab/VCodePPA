//SystemVerilog
// Top-level module for hierarchical floating-point mantissa rotation
module float_rot #(
    parameter EXP_WIDTH = 5,
    parameter MANT_WIDTH = 10
)(
    input  [EXP_WIDTH+MANT_WIDTH:0]   float_in,
    input  [4:0]                      shift_amt,
    output [EXP_WIDTH+MANT_WIDTH:0]   float_out
);

    // Internal signals
    wire                               sign_bit;
    wire [EXP_WIDTH-1:0]               exponent_bits;
    wire [MANT_WIDTH:0]                mantissa_bits;
    wire [MANT_WIDTH:0]                rotated_mantissa;
    wire [MANT_WIDTH-1:0]              mantissa_packed;

    // Extract sign bit submodule
    sign_extractor #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_sign_extractor (
        .float_in(float_in),
        .sign_out(sign_bit)
    );

    // Extract exponent field submodule
    exponent_extractor #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_exponent_extractor (
        .float_in(float_in),
        .exponent_out(exponent_bits)
    );

    // Extract mantissa bits submodule
    mantissa_extractor #(
        .MANT_WIDTH(MANT_WIDTH)
    ) u_mantissa_extractor (
        .float_in(float_in),
        .mantissa_out(mantissa_bits)
    );

    // Mantissa rotation submodule
    mantissa_rotator #(
        .MANT_WIDTH(MANT_WIDTH)
    ) u_mantissa_rotator (
        .mantissa_in(mantissa_bits),
        .shift_amt(shift_amt),
        .mantissa_out(rotated_mantissa)
    );

    // Mantissa truncation submodule (extracts [MANT_WIDTH:1])
    mantissa_truncator #(
        .MANT_WIDTH(MANT_WIDTH)
    ) u_mantissa_truncator (
        .mantissa_in(rotated_mantissa),
        .mantissa_trunc(mantissa_packed)
    );

    // Output packing submodule
    float_packer #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_float_packer (
        .sign_in(sign_bit),
        .exponent_in(exponent_bits),
        .mantissa_in(mantissa_packed),
        .float_out(float_out)
    );

endmodule

// -------------------------------------------------------------
// sign_extractor: Extracts the sign bit from floating-point input
// -------------------------------------------------------------
module sign_extractor #(
    parameter EXP_WIDTH = 5,
    parameter MANT_WIDTH = 10
)(
    input  [EXP_WIDTH+MANT_WIDTH:0] float_in,
    output                          sign_out
);
    assign sign_out = float_in[EXP_WIDTH+MANT_WIDTH];
endmodule

// -----------------------------------------------------------------
// exponent_extractor: Extracts the exponent field from input vector
// -----------------------------------------------------------------
module exponent_extractor #(
    parameter EXP_WIDTH = 5,
    parameter MANT_WIDTH = 10
)(
    input  [EXP_WIDTH+MANT_WIDTH:0] float_in,
    output [EXP_WIDTH-1:0]          exponent_out
);
    assign exponent_out = float_in[EXP_WIDTH+MANT_WIDTH-1:MANT_WIDTH];
endmodule

// -------------------------------------------------------------------
// mantissa_extractor: Extracts the mantissa field from input vector
// -------------------------------------------------------------------
module mantissa_extractor #(
    parameter MANT_WIDTH = 10
)(
    input  [MANT_WIDTH + 5:0] float_in, // EXP_WIDTH is not needed for slicing
    output [MANT_WIDTH:0]     mantissa_out
);
    assign mantissa_out = float_in[MANT_WIDTH:0];
endmodule

// -------------------------------------------------------------------------
// mantissa_rotator: Performs right rotation on mantissa bits
// -------------------------------------------------------------------------
module mantissa_rotator #(
    parameter MANT_WIDTH = 10
)(
    input  [MANT_WIDTH:0] mantissa_in,
    input  [4:0]          shift_amt,
    output [MANT_WIDTH:0] mantissa_out
);
    // Concatenate mantissa for rotation and perform right shift
    assign mantissa_out = {mantissa_in, mantissa_in} >> shift_amt;
endmodule

// ---------------------------------------------------------------------------
// mantissa_truncator: Truncates rotated mantissa to required width [MANT_WIDTH:1]
// ---------------------------------------------------------------------------
module mantissa_truncator #(
    parameter MANT_WIDTH = 10
)(
    input  [MANT_WIDTH:0] mantissa_in,
    output [MANT_WIDTH-1:0] mantissa_trunc
);
    assign mantissa_trunc = mantissa_in[MANT_WIDTH:1];
endmodule

// -----------------------------------------------------------------------------
// float_packer: Assembles the sign, exponent, and mantissa fields into output
// -----------------------------------------------------------------------------
module float_packer #(
    parameter EXP_WIDTH = 5,
    parameter MANT_WIDTH = 10
)(
    input                       sign_in,
    input      [EXP_WIDTH-1:0]  exponent_in,
    input      [MANT_WIDTH-1:0] mantissa_in,
    output reg [EXP_WIDTH+MANT_WIDTH:0] float_out
);
    always @(*) begin
        float_out = {sign_in, exponent_in, mantissa_in};
    end
endmodule