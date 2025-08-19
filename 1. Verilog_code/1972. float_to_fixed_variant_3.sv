//SystemVerilog
// Top-level module: float_to_fixed
// Function: Converts floating-point input to fixed-point output with overflow detection
module float_to_fixed #(
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter EXP_W = 5,
    parameter MANT_W = 10
)(
    input wire [EXP_W+MANT_W:0] float_in,
    output wire [INT_W+FRAC_W-1:0] fixed_out,
    output wire overflow
);

    // Internal wires for inter-module connections
    wire sign_bit;
    wire [EXP_W-1:0] exponent;
    wire [MANT_W-1:0] mantissa;
    wire [MANT_W:0] full_mantissa;
    wire signed [EXP_W:0] shift_amount;
    wire [MANT_W+INT_W+FRAC_W:0] shifted_value;
    wire [INT_W+FRAC_W-1:0] abs_fixed_result;
    wire overflow_next;
    wire [INT_W+FRAC_W-1:0] fixed_out_next;

    // Submodule: float_parser
    float_parser #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) u_float_parser (
        .float_in(float_in),
        .sign_bit(sign_bit),
        .exponent(exponent),
        .mantissa(mantissa),
        .full_mantissa(full_mantissa)
    );

    // Submodule: shift_amount_calc
    shift_amount_calc #(
        .EXP_W(EXP_W),
        .FRAC_W(FRAC_W)
    ) u_shift_amount_calc (
        .exponent(exponent),
        .shift_amount(shift_amount)
    );

    // Submodule: mantissa_shifter
    mantissa_shifter #(
        .INT_W(INT_W),
        .FRAC_W(FRAC_W),
        .MANT_W(MANT_W)
    ) u_mantissa_shifter (
        .full_mantissa(full_mantissa),
        .shift_amount(shift_amount),
        .shifted_value(shifted_value)
    );

    // Submodule: overflow_detector
    overflow_detector #(
        .MANT_W(MANT_W),
        .INT_W(INT_W),
        .FRAC_W(FRAC_W)
    ) u_overflow_detector (
        .shifted_value(shifted_value),
        .overflow_next(overflow_next)
    );

    // Submodule: abs_result_extractor
    abs_result_extractor #(
        .INT_W(INT_W),
        .FRAC_W(FRAC_W),
        .MANT_W(MANT_W)
    ) u_abs_result_extractor (
        .shifted_value(shifted_value),
        .abs_fixed_result(abs_fixed_result)
    );

    // Submodule: sign_adjust
    sign_adjust #(
        .INT_W(INT_W),
        .FRAC_W(FRAC_W)
    ) u_sign_adjust (
        .sign_bit(sign_bit),
        .abs_fixed_result(abs_fixed_result),
        .fixed_out_next(fixed_out_next)
    );

    // Output assignments
    assign fixed_out = fixed_out_next;
    assign overflow = overflow_next;

endmodule

// ---------------------------------------------------------------
// Submodule: float_parser
// Function: Extracts sign, exponent, mantissa, and forms full mantissa (with leading 1)
module float_parser #(
    parameter EXP_W = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output wire sign_bit,
    output wire [EXP_W-1:0] exponent,
    output wire [MANT_W-1:0] mantissa,
    output wire [MANT_W:0] full_mantissa
);
    assign sign_bit = float_in[EXP_W+MANT_W];
    assign exponent = float_in[EXP_W+MANT_W-1:MANT_W];
    assign mantissa = float_in[MANT_W-1:0];
    assign full_mantissa = {1'b1, mantissa}; // Implicit leading 1
endmodule

// ---------------------------------------------------------------
// Submodule: shift_amount_calc
// Function: Calculates the shift amount for mantissa normalization
module shift_amount_calc #(
    parameter EXP_W = 5,
    parameter FRAC_W = 8
)(
    input  wire [EXP_W-1:0] exponent,
    output wire signed [EXP_W:0] shift_amount
);
    // Bias = 2^(EXP_W-1) - 1, but as constant all 1s in (EXP_W-1) bits
    wire [EXP_W-1:0] bias = {(EXP_W-1){1'b1}};
    assign shift_amount = $signed({1'b0, exponent}) - $signed({1'b0, bias}) - FRAC_W;
endmodule

// ---------------------------------------------------------------
// Submodule: mantissa_shifter
// Function: Shifts the mantissa left or right according to shift amount
module mantissa_shifter #(
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter MANT_W = 10
)(
    input  wire [MANT_W:0] full_mantissa,
    input  wire signed [($clog2(MANT_W+INT_W+FRAC_W+2))-1:0] shift_amount,
    output wire [MANT_W+INT_W+FRAC_W:0] shifted_value
);
    wire signed [($clog2(MANT_W+INT_W+FRAC_W+2))-1:0] zero = 0;
    reg [MANT_W+INT_W+FRAC_W:0] shifted;
    integer i;

    always @* begin
        if (shift_amount >= 0)
            shifted = full_mantissa << shift_amount;
        else
            shifted = full_mantissa >> -shift_amount;
    end

    assign shifted_value = shifted;
endmodule

// ---------------------------------------------------------------
// Submodule: overflow_detector
// Function: Detects if overflow occurs (if upper bits are non-zero)
module overflow_detector #(
    parameter MANT_W = 10,
    parameter INT_W = 8,
    parameter FRAC_W = 8
)(
    input  wire [MANT_W+INT_W+FRAC_W:0] shifted_value,
    output wire overflow_next
);
    assign overflow_next = |shifted_value[MANT_W+INT_W+FRAC_W:INT_W+FRAC_W];
endmodule

// ---------------------------------------------------------------
// Submodule: abs_result_extractor
// Function: Extracts the lower INT_W+FRAC_W bits as the absolute fixed result
module abs_result_extractor #(
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter MANT_W = 10
)(
    input  wire [MANT_W+INT_W+FRAC_W:0] shifted_value,
    output wire [INT_W+FRAC_W-1:0] abs_fixed_result
);
    assign abs_fixed_result = shifted_value[INT_W+FRAC_W-1:0];
endmodule

// ---------------------------------------------------------------
// Submodule: sign_adjust
// Function: Adjusts the sign of the fixed-point output
module sign_adjust #(
    parameter INT_W = 8,
    parameter FRAC_W = 8
)(
    input  wire sign_bit,
    input  wire [INT_W+FRAC_W-1:0] abs_fixed_result,
    output wire [INT_W+FRAC_W-1:0] fixed_out_next
);
    assign fixed_out_next = sign_bit ? (~abs_fixed_result + 1'b1) : abs_fixed_result;
endmodule