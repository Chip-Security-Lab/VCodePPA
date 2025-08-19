//SystemVerilog
module fixed2float #(
    parameter INT_BITS = 8,
    parameter FRACT_BITS = 8,
    parameter EXP_BITS = 8,
    parameter MANT_BITS = 23
)(
    input  wire signed [INT_BITS+FRACT_BITS-1:0] fixed_in,
    output reg  [EXP_BITS+MANT_BITS:0] float_out
);

    // Stage 1: Sign and absolute value extraction
    reg                          stage1_sign;
    reg  [INT_BITS+FRACT_BITS-1:0] stage1_abs_val;

    // Stage 2: Leading zero count and shift amount calculation
    reg [$clog2(INT_BITS+FRACT_BITS)-1:0] stage2_leading_zeros;
    reg [$clog2(INT_BITS+FRACT_BITS)-1:0] stage2_shift_amt;
    reg  [INT_BITS+FRACT_BITS-1:0]        stage2_abs_val;
    reg                                   stage2_sign;

    // Stage 3: Exponent and mantissa computation
    reg  [EXP_BITS-1:0]  stage3_exponent;
    reg  [MANT_BITS-1:0] stage3_mantissa;
    reg                  stage3_sign;

    // Pipeline Stage 1: Extract sign and absolute value (expanded ?:)
    always @(*) begin
        stage1_sign = fixed_in[INT_BITS+FRACT_BITS-1];
        if (fixed_in[INT_BITS+FRACT_BITS-1]) begin
            stage1_abs_val = -fixed_in;
        end else begin
            stage1_abs_val = fixed_in;
        end
    end

    // Pipeline Stage 2: Compute leading zeros and shift amount
    always @(*) begin : leading_zero_counter
        integer i;
        stage2_leading_zeros = 0;
        for (i = INT_BITS+FRACT_BITS-1; i >= 0; i = i - 1) begin
            if (stage1_abs_val[i] == 1'b1)
                stage2_leading_zeros = INT_BITS+FRACT_BITS-1 - i;
        end
        stage2_shift_amt = INT_BITS + FRACT_BITS - 1 - stage2_leading_zeros;
        stage2_abs_val   = stage1_abs_val;
        stage2_sign      = stage1_sign;
    end

    // Pipeline Stage 3: Exponent and Mantissa calculation (expanded ?:)
    always @(*) begin
        stage3_sign     = stage2_sign;
        stage3_exponent = 127 + stage2_shift_amt - FRACT_BITS;
        if (stage2_shift_amt < MANT_BITS) begin
            stage3_mantissa = stage2_abs_val << (MANT_BITS - stage2_shift_amt);
        end else begin
            stage3_mantissa = stage2_abs_val >> (stage2_shift_amt - MANT_BITS);
        end
    end

    // Output Assembly
    always @(*) begin
        float_out[EXP_BITS+MANT_BITS]        = stage3_sign;
        float_out[EXP_BITS+MANT_BITS-1:MANT_BITS] = stage3_exponent;
        float_out[MANT_BITS-1:0]             = stage3_mantissa;
    end

endmodule