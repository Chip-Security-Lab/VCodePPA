//SystemVerilog
module fp_comparator(
    input [31:0] fp_a,
    input [31:0] fp_b,
    output reg eq_result,
    output reg gt_result,
    output reg lt_result,
    output reg unordered
);

    wire a_is_zero, b_is_zero, a_is_inf, b_is_inf, a_is_nan, b_is_nan;
    wire [7:0] a_exp, b_exp;
    wire [22:0] a_mant, b_mant;
    wire a_sign, b_sign;
    wire [31:0] abs_a, abs_b;
    wire exp_gt, exp_eq, mant_gt;
    wire same_sign, both_inf, both_zero;

    special_case_detector detector(
        .fp_a(fp_a),
        .fp_b(fp_b),
        .a_is_zero(a_is_zero),
        .b_is_zero(b_is_zero),
        .a_is_inf(a_is_inf),
        .b_is_inf(b_is_inf),
        .a_is_nan(a_is_nan),
        .b_is_nan(b_is_nan),
        .a_exp(a_exp),
        .b_exp(b_exp),
        .a_mant(a_mant),
        .b_mant(b_mant),
        .a_sign(a_sign),
        .b_sign(b_sign)
    );

    comparison_logic comparator(
        .a_is_nan(a_is_nan),
        .b_is_nan(b_is_nan),
        .a_is_zero(a_is_zero),
        .b_is_zero(b_is_zero),
        .a_is_inf(a_is_inf),
        .b_is_inf(b_is_inf),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_exp(a_exp),
        .b_exp(b_exp),
        .a_mant(a_mant),
        .b_mant(b_mant),
        .fp_a(fp_a),
        .fp_b(fp_b),
        .eq_result(eq_result),
        .gt_result(gt_result),
        .lt_result(lt_result),
        .unordered(unordered)
    );

endmodule

module special_case_detector(
    input [31:0] fp_a,
    input [31:0] fp_b,
    output a_is_zero,
    output b_is_zero,
    output a_is_inf,
    output b_is_inf,
    output a_is_nan,
    output b_is_nan,
    output [7:0] a_exp,
    output [7:0] b_exp,
    output [22:0] a_mant,
    output [22:0] b_mant,
    output a_sign,
    output b_sign
);
    wire [7:0] exp_mask = 8'hFF;
    wire [22:0] mant_mask = 23'h0;
    
    assign a_sign = fp_a[31];
    assign b_sign = fp_b[31];
    assign a_exp = fp_a[30:23];
    assign b_exp = fp_b[30:23];
    assign a_mant = fp_a[22:0];
    assign b_mant = fp_b[22:0];
    
    assign a_is_zero = (a_exp == 8'h00) & (a_mant == mant_mask);
    assign b_is_zero = (b_exp == 8'h00) & (b_mant == mant_mask);
    assign a_is_inf = (a_exp == exp_mask) & (a_mant == mant_mask);
    assign b_is_inf = (b_exp == exp_mask) & (b_mant == mant_mask);
    assign a_is_nan = (a_exp == exp_mask) & (a_mant != mant_mask);
    assign b_is_nan = (b_exp == exp_mask) & (b_mant != mant_mask);
endmodule

module comparison_logic(
    input a_is_nan,
    input b_is_nan,
    input a_is_zero,
    input b_is_zero,
    input a_is_inf,
    input b_is_inf,
    input a_sign,
    input b_sign,
    input [7:0] a_exp,
    input [7:0] b_exp,
    input [22:0] a_mant,
    input [22:0] b_mant,
    input [31:0] fp_a,
    input [31:0] fp_b,
    output reg eq_result,
    output reg gt_result,
    output reg lt_result,
    output reg unordered
);
    wire same_sign = (a_sign == b_sign);
    wire both_inf = a_is_inf & b_is_inf;
    wire both_zero = a_is_zero & b_is_zero;
    wire exp_gt = (a_exp > b_exp);
    wire exp_eq = (a_exp == b_exp);
    wire mant_gt = (a_mant > b_mant);
    wire abs_gt = exp_gt | (exp_eq & mant_gt);

    always @(*) begin
        eq_result = 1'b0;
        gt_result = 1'b0;
        lt_result = 1'b0;
        unordered = 1'b0;
        
        if (a_is_nan | b_is_nan) begin
            unordered = 1'b1;
        end
        else if (fp_a == fp_b | both_zero) begin
            eq_result = 1'b1;
        end
        else if (both_inf) begin
            if (same_sign)
                eq_result = 1'b1;
            else if (a_sign)
                lt_result = 1'b1;
            else
                gt_result = 1'b1;
        end
        else if (!same_sign) begin
            if (a_sign)
                lt_result = 1'b1;
            else
                gt_result = 1'b1;
        end
        else if (!a_sign) begin
            if (abs_gt)
                gt_result = 1'b1;
            else
                lt_result = 1'b1;
        end
        else begin
            if (abs_gt)
                lt_result = 1'b1;
            else
                gt_result = 1'b1;
        end
    end
endmodule