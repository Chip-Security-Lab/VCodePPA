//SystemVerilog
module fixed2float #(
    parameter INT_BITS = 8,
    parameter FRACT_BITS = 8,
    parameter EXP_BITS = 8,
    parameter MANT_BITS = 23
)(
    input  wire signed [INT_BITS+FRACT_BITS-1:0] fixed_in,
    output reg        [EXP_BITS+MANT_BITS:0]    float_out
);

    // Pipeline Stage 1: Input Latching and Sign Extraction
    reg signed [INT_BITS+FRACT_BITS-1:0] fixed_in_stage1;
    reg                                   sign_stage1;
    always @(*) begin
        fixed_in_stage1 = fixed_in;
        sign_stage1 = fixed_in[INT_BITS+FRACT_BITS-1];
    end

    // Pipeline Stage 2: Absolute Value Calculation
    reg [INT_BITS+FRACT_BITS-1:0] abs_val_stage2;
    always @(*) begin
        abs_val_stage2 = sign_stage1 ? -fixed_in_stage1 : fixed_in_stage1;
    end

    // Pipeline Stage 3: Leading Zero Detection
    reg [$clog2(INT_BITS+FRACT_BITS)-1:0] leading_zeros_stage3;
    integer i;
    always @(*) begin : leading_zero_counter
        leading_zeros_stage3 = 0;
        for (i = INT_BITS+FRACT_BITS-1; i >= 0; i = i - 1) begin
            if (abs_val_stage2[i] == 1'b1) begin
                leading_zeros_stage3 = (INT_BITS+FRACT_BITS-1) - i;
                disable leading_zero_counter;
            end
        end
    end

    // Pipeline Stage 4: Exponent and Mantissa Calculation
    reg [$clog2(INT_BITS+FRACT_BITS)-1:0] shift_amt_stage4;
    reg [EXP_BITS-1:0]                    exponent_stage4;
    reg [MANT_BITS-1:0]                   mantissa_stage4;
    always @(*) begin
        shift_amt_stage4 = INT_BITS + FRACT_BITS - 1 - leading_zeros_stage3;
        exponent_stage4 = 127 + shift_amt_stage4 - FRACT_BITS;
        mantissa_stage4 = abs_val_stage2 << (MANT_BITS - shift_amt_stage4);
    end

    // Pipeline Stage 5: Output Assembly
    always @(*) begin
        float_out[EXP_BITS+MANT_BITS]               = sign_stage1;
        float_out[EXP_BITS+MANT_BITS-1:MANT_BITS]   = exponent_stage4;
        float_out[MANT_BITS-1:0]                    = mantissa_stage4;
    end

endmodule