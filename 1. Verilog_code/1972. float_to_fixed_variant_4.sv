//SystemVerilog
// Top-level module: float_to_fixed
module float_to_fixed #(
    parameter INT_W  = 8,
    parameter FRAC_W = 8,
    parameter EXP_W  = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output wire [INT_W+FRAC_W-1:0] fixed_out,
    output wire overflow
);

    // Signal Declarations
    wire sign_bit;
    wire [EXP_W-1:0] exponent;
    wire [MANT_W-1:0] mantissa;
    wire [MANT_W:0] full_mantissa;
    wire signed [EXP_W:0] shift_amount;
    wire [MANT_W+INT_W+FRAC_W:0] shifted_mantissa;
    wire [INT_W+FRAC_W-1:0] abs_fixed_result;
    wire [MANT_W+INT_W+FRAC_W:0] shifted_left;
    wire [MANT_W+INT_W+FRAC_W:0] shifted_right;
    wire left_shift_sel;

    // Submodule: float_decoder
    // Extracts sign, exponent, and mantissa from input float
    float_decoder #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) u_float_decoder (
        .float_in(float_in),
        .sign_bit(sign_bit),
        .exponent(exponent),
        .mantissa(mantissa),
        .full_mantissa(full_mantissa)
    );

    // Submodule: shift_amount_calc
    // Calculates the shift amount based on exponent and FRAC_W
    shift_amount_calc #(
        .EXP_W(EXP_W),
        .FRAC_W(FRAC_W)
    ) u_shift_amount_calc (
        .exponent(exponent),
        .shift_amount(shift_amount)
    );

    // Submodule: barrel_shifter_left
    // Performs left barrel shift
    barrel_shifter_left #(
        .DATA_W(MANT_W+1),
        .SHIFT_W(EXP_W+1),
        .OUT_W(MANT_W+INT_W+FRAC_W+1)
    ) u_barrel_shifter_left (
        .data_in(full_mantissa),
        .shift_val(shift_amount[EXP_W:0]),
        .shifted_data(shifted_left)
    );

    // Submodule: barrel_shifter_right
    // Performs right barrel shift (logical)
    barrel_shifter_right #(
        .DATA_W(MANT_W+1),
        .SHIFT_W(EXP_W+1),
        .OUT_W(MANT_W+INT_W+FRAC_W+1)
    ) u_barrel_shifter_right (
        .data_in(full_mantissa),
        .shift_val(-shift_amount[EXP_W:0]),
        .shifted_data(shifted_right)
    );

    // Submodule: shift_mux
    // Selects left or right shifted mantissa based on shift_amount sign
    shift_mux #(
        .DATA_W(MANT_W+INT_W+FRAC_W+1)
    ) u_shift_mux (
        .shift_amount(shift_amount),
        .shifted_left(shifted_left),
        .shifted_right(shifted_right),
        .shifted_mantissa(shifted_mantissa),
        .left_shift_sel(left_shift_sel)
    );

    // Submodule: fixed_result
    // Handles absolute fixed result, overflow detection, and final sign application
    fixed_result #(
        .INT_W(INT_W),
        .FRAC_W(FRAC_W),
        .MANT_W(MANT_W)
    ) u_fixed_result (
        .sign_bit(sign_bit),
        .shifted_mantissa(shifted_mantissa),
        .abs_fixed_result(abs_fixed_result),
        .fixed_out(fixed_out),
        .overflow(overflow)
    );

endmodule

//-----------------------------------------------------------------------------
// float_decoder: Extracts sign, exponent, mantissa, and builds full mantissa
//-----------------------------------------------------------------------------
module float_decoder #(
    parameter EXP_W  = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output wire sign_bit,
    output wire [EXP_W-1:0] exponent,
    output wire [MANT_W-1:0] mantissa,
    output wire [MANT_W:0] full_mantissa
);
    assign sign_bit     = float_in[EXP_W+MANT_W];
    assign exponent     = float_in[EXP_W+MANT_W-1:MANT_W];
    assign mantissa     = float_in[MANT_W-1:0];
    assign full_mantissa = {1'b1, mantissa}; // Implied leading 1
endmodule

//-----------------------------------------------------------------------------
// shift_amount_calc: Calculates the shift amount from exponent and FRAC_W
//-----------------------------------------------------------------------------
module shift_amount_calc #(
    parameter EXP_W = 5,
    parameter FRAC_W = 8
)(
    input  wire [EXP_W-1:0] exponent,
    output wire signed [EXP_W:0] shift_amount
);
    // Reference bias = 2^(EXP_W-1)-1
    wire [EXP_W-1:0] bias;
    assign bias = { {(EXP_W-1){1'b1}}, 1'b1 };
    assign shift_amount = $signed({1'b0, exponent}) - $signed({1'b0, bias}) - FRAC_W;
endmodule

//-----------------------------------------------------------------------------
// barrel_shifter_left: Parameterized left barrel shifter
//-----------------------------------------------------------------------------
module barrel_shifter_left #(
    parameter DATA_W = 11,
    parameter SHIFT_W = 6,
    parameter OUT_W = 27
)(
    input  wire [DATA_W-1:0] data_in,
    input  wire [SHIFT_W-1:0] shift_val,
    output wire [OUT_W-1:0] shifted_data
);
    reg [OUT_W-1:0] temp;
    integer i;
    always @* begin
        temp = {{(OUT_W-DATA_W){1'b0}}, data_in};
        for (i=SHIFT_W-1; i>=0; i=i-1) begin
            if (shift_val[i])
                temp = temp << (1 << i);
        end
    end
    assign shifted_data = temp;
endmodule

//-----------------------------------------------------------------------------
// barrel_shifter_right: Parameterized right barrel shifter (logical)
//-----------------------------------------------------------------------------
module barrel_shifter_right #(
    parameter DATA_W = 11,
    parameter SHIFT_W = 6,
    parameter OUT_W = 27
)(
    input  wire [DATA_W-1:0] data_in,
    input  wire [SHIFT_W-1:0] shift_val,
    output wire [OUT_W-1:0] shifted_data
);
    reg [OUT_W-1:0] temp;
    integer i;
    always @* begin
        temp = {{(OUT_W-DATA_W){1'b0}}, data_in};
        for (i=SHIFT_W-1; i>=0; i=i-1) begin
            if (shift_val[i])
                temp = temp >> (1 << i);
        end
    end
    assign shifted_data = temp;
endmodule

//-----------------------------------------------------------------------------
// shift_mux: Selects left or right shifted mantissa based on shift_amount sign
//-----------------------------------------------------------------------------
module shift_mux #(
    parameter DATA_W = 27
)(
    input  wire signed [DATA_W-17:0] shift_amount, // typically [5:0]
    input  wire [DATA_W-1:0] shifted_left,
    input  wire [DATA_W-1:0] shifted_right,
    output wire [DATA_W-1:0] shifted_mantissa,
    output wire left_shift_sel
);
    assign left_shift_sel = (shift_amount >= 0);
    assign shifted_mantissa = left_shift_sel ? shifted_left : shifted_right;
endmodule

//-----------------------------------------------------------------------------
// fixed_result: Computes abs fixed result, overflow, and applies sign
//-----------------------------------------------------------------------------
module fixed_result #(
    parameter INT_W  = 8,
    parameter FRAC_W = 8,
    parameter MANT_W = 10
)(
    input  wire sign_bit,
    input  wire [MANT_W+INT_W+FRAC_W:0] shifted_mantissa,
    output wire [INT_W+FRAC_W-1:0] abs_fixed_result,
    output wire [INT_W+FRAC_W-1:0] fixed_out,
    output wire overflow
);
    assign abs_fixed_result = shifted_mantissa[INT_W+FRAC_W-1:0];
    assign overflow = |shifted_mantissa[MANT_W+INT_W+FRAC_W:INT_W+FRAC_W];
    assign fixed_out = sign_bit ? (~abs_fixed_result + 1'b1) : abs_fixed_result;
endmodule