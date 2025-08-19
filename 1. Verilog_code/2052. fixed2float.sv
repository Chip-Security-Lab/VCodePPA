module fixed2float #(parameter INT_BITS = 8, FRACT_BITS = 8,
                   parameter EXP_BITS = 8, MANT_BITS = 23) (
    input wire signed [INT_BITS+FRACT_BITS-1:0] fixed_in,
    output reg [EXP_BITS+MANT_BITS:0] float_out
);
    wire sign;
    wire [INT_BITS+FRACT_BITS-1:0] abs_val;
    wire [$clog2(INT_BITS+FRACT_BITS)-1:0] leading_zeros;
    wire [$clog2(INT_BITS+FRACT_BITS)-1:0] shift_amt;
    
    assign sign = fixed_in[INT_BITS+FRACT_BITS-1];
    assign abs_val = sign ? -fixed_in : fixed_in;
    
    // Count leading zeros (would be replaced with proper leading zero counter)
    // This is a simplified version
    assign leading_zeros = abs_val[INT_BITS+FRACT_BITS-1] ? 0 : 1;
    assign shift_amt = INT_BITS + FRACT_BITS - 1 - leading_zeros;
    
    always @(*) begin
        float_out[EXP_BITS+MANT_BITS] = sign;
        float_out[EXP_BITS+MANT_BITS-1:MANT_BITS] = 127 + shift_amt - FRACT_BITS;
        float_out[MANT_BITS-1:0] = abs_val << (MANT_BITS - shift_amt);
    end
endmodule