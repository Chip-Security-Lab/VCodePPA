//SystemVerilog
module fp2fix_sync #(
    parameter Q = 8
)(
    input clk,
    input rst,
    input [31:0] fp,
    output reg [30:0] fixed
);

    // Combination Logic: decode input
    wire sign_comb;
    wire [7:0] exp_comb;
    wire [23:0] mant_comb;
    wire [7:0] shift_amt_comb;
    wire [30:0] shifted_mantissa_comb;
    reg [30:0] fixed_next_comb;

    assign sign_comb = fp[31];
    assign exp_comb = fp[30:23] - 8'd127;
    assign mant_comb = {1'b1, fp[22:0]};
    assign shift_amt_comb = exp_comb - Q;
    assign shifted_mantissa_comb = mant_comb << shift_amt_comb;

    always @(*) begin
        if (sign_comb)
            fixed_next_comb = -shifted_mantissa_comb;
        else
            fixed_next_comb = shifted_mantissa_comb;
    end

    // Register after combination logic (forward retiming)
    always @(posedge clk) begin
        if (rst)
            fixed <= 31'd0;
        else
            fixed <= fixed_next_comb;
    end

endmodule