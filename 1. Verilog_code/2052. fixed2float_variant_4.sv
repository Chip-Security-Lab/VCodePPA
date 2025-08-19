//SystemVerilog
module fixed2float #(
    parameter INT_BITS = 8,
    parameter FRACT_BITS = 8,
    parameter EXP_BITS = 8,
    parameter MANT_BITS = 23
) (
    input wire signed [INT_BITS+FRACT_BITS-1:0] fixed_in,
    output reg [EXP_BITS+MANT_BITS:0] float_out
);
    wire sign_bit;
    reg [INT_BITS+FRACT_BITS-1:0] abs_value;
    reg [$clog2(INT_BITS+FRACT_BITS)-1:0] leading_zeros;
    reg [$clog2(INT_BITS+FRACT_BITS)-1:0] shift_amount;
    reg [EXP_BITS-1:0] exponent_field;
    reg [MANT_BITS-1:0] mantissa_field;

    assign sign_bit = fixed_in[INT_BITS+FRACT_BITS-1];

    always @(*) begin
        if (sign_bit && (fixed_in != 0)) begin
            abs_value = -fixed_in;
        end else if (!sign_bit && (fixed_in != 0)) begin
            abs_value = fixed_in;
        end else begin
            abs_value = { (INT_BITS+FRACT_BITS){1'b0} };
        end
    end

    always @(*) begin
        if (abs_value[INT_BITS+FRACT_BITS-1]) begin
            leading_zeros = {($clog2(INT_BITS+FRACT_BITS)){1'b0}};
        end else if (!abs_value[INT_BITS+FRACT_BITS-1] && abs_value != 0) begin
            leading_zeros = {{($clog2(INT_BITS+FRACT_BITS)-1){1'b0}}, 1'b1};
        end else begin
            leading_zeros = {($clog2(INT_BITS+FRACT_BITS)){1'b0}};
        end
    end

    always @(*) begin
        shift_amount = INT_BITS + FRACT_BITS - 1 - leading_zeros;
    end

    always @(*) begin
        exponent_field = 127 + shift_amount - FRACT_BITS;
    end

    always @(*) begin
        mantissa_field = abs_value << (MANT_BITS - shift_amount);
    end

    always @(*) begin
        float_out[EXP_BITS+MANT_BITS] = sign_bit;
        float_out[EXP_BITS+MANT_BITS-1:MANT_BITS] = exponent_field;
        float_out[MANT_BITS-1:0] = mantissa_field;
    end

endmodule