module float_to_fixed #(parameter INT_W=8, FRAC_W=8, EXP_W=5, MANT_W=10)(
    input wire [EXP_W+MANT_W:0] float_in,
    output reg [INT_W+FRAC_W-1:0] fixed_out,
    output reg overflow
);
    wire sign = float_in[EXP_W+MANT_W];
    wire [EXP_W-1:0] exp = float_in[EXP_W+MANT_W-1:MANT_W];
    wire [MANT_W-1:0] mant = float_in[MANT_W-1:0];
    wire [MANT_W:0] full_mant = {1'b1, mant};  // 隐含的前导1
    
    reg [MANT_W+INT_W+FRAC_W:0] shifted;
    reg [INT_W+FRAC_W-1:0] abs_result;
    reg signed [EXP_W:0] shift_amt;
    
    always @* begin
        shift_amt = exp - {1'b0, {(EXP_W-1){1'b1}}} - FRAC_W;
        shifted = shift_amt >= 0 ? full_mant << shift_amt : full_mant >> -shift_amt;
        abs_result = shifted[INT_W+FRAC_W-1:0];
        overflow = |shifted[MANT_W+INT_W+FRAC_W:INT_W+FRAC_W];
        fixed_out = sign ? (~abs_result + 1'b1) : abs_result;
    end
endmodule