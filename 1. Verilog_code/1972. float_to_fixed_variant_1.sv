//SystemVerilog
// Top-level module: float_to_fixed
module float_to_fixed #(
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter EXP_W = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output wire [INT_W+FRAC_W-1:0] fixed_out,
    output wire overflow
);

    // Internal signals
    wire sign_bit;
    wire [EXP_W-1:0] exponent;
    wire [MANT_W-1:0] mantissa;
    wire [MANT_W:0] normalized_mantissa;
    wire signed [EXP_W:0] shift_amount;
    wire [MANT_W+INT_W+FRAC_W:0] shifted_result;
    wire overflow_int;

    // Submodule: float_decoder
    float_decoder #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) u_float_decoder (
        .float_in(float_in),
        .sign_bit(sign_bit),
        .exponent(exponent),
        .mantissa(mantissa),
        .normalized_mantissa(normalized_mantissa)
    );

    // Submodule: shift_amount_calc
    shift_amount_calc #(
        .EXP_W(EXP_W),
        .FRAC_W(FRAC_W)
    ) u_shift_amount_calc (
        .exponent(exponent),
        .shift_amount(shift_amount)
    );

    // Submodule: mantissa_shifter (桶形移位器实现)
    mantissa_shifter #(
        .MANT_W(MANT_W),
        .INT_W(INT_W),
        .FRAC_W(FRAC_W),
        .EXP_W(EXP_W)
    ) u_mantissa_shifter (
        .normalized_mantissa(normalized_mantissa),
        .shift_amount(shift_amount),
        .shifted_result(shifted_result)
    );

    // Submodule: fixed_postproc
    fixed_postproc #(
        .INT_W(INT_W),
        .FRAC_W(FRAC_W),
        .MANT_W(MANT_W),
        .EXP_W(EXP_W)
    ) u_fixed_postproc (
        .shifted_result(shifted_result),
        .sign_bit(sign_bit),
        .fixed_out(fixed_out),
        .overflow(overflow_int)
    );

    assign overflow = overflow_int;

endmodule

//------------------------ 子模块定义 ------------------------

// 浮点数解码模块
module float_decoder #(
    parameter EXP_W = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output wire sign_bit,
    output wire [EXP_W-1:0] exponent,
    output wire [MANT_W-1:0] mantissa,
    output wire [MANT_W:0] normalized_mantissa
);
    assign sign_bit = float_in[EXP_W+MANT_W];
    assign exponent = float_in[EXP_W+MANT_W-1:MANT_W];
    assign mantissa = float_in[MANT_W-1:0];
    assign normalized_mantissa = {1'b1, mantissa}; // 隐含前导1
endmodule

// 移位量计算模块
module shift_amount_calc #(
    parameter EXP_W = 5,
    parameter FRAC_W = 8
)(
    input  wire [EXP_W-1:0] exponent,
    output wire signed [EXP_W:0] shift_amount
);
    wire [EXP_W-1:0] bias;
    assign bias = {(EXP_W-1){1'b1}};
    assign shift_amount = $signed({1'b0, exponent}) - $signed({1'b0, bias}) - FRAC_W;
endmodule

// 桶形移位模块（多路复用器结构）
module mantissa_shifter #(
    parameter MANT_W = 10,
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter EXP_W = 5
)(
    input  wire [MANT_W:0] normalized_mantissa,
    input  wire signed [EXP_W:0] shift_amount,
    output wire [MANT_W+INT_W+FRAC_W:0] shifted_result
);

    localparam SH_W = EXP_W+1; // 移位量最大宽度
    localparam DATA_W = MANT_W+1;
    localparam OUT_W = MANT_W+INT_W+FRAC_W+1;

    wire [SH_W-1:0] abs_shift_val;
    wire shift_left;
    assign shift_left = (shift_amount >= 0);
    assign abs_shift_val = shift_left ? shift_amount[SH_W-1:0] : (~shift_amount[SH_W-1:0] + 1'b1);

    // 输入数据对齐到桶形移位器输入宽度
    wire [OUT_W-1:0] in_data;
    assign in_data = {{(OUT_W-DATA_W){1'b0}}, normalized_mantissa};

    // 桶形移位器左移
    wire [OUT_W-1:0] left_shift_stage0;
    wire [OUT_W-1:0] left_shift_stage1;
    wire [OUT_W-1:0] left_shift_stage2;
    wire [OUT_W-1:0] left_shift_stage3;
    wire [OUT_W-1:0] left_shift_stage4;

    assign left_shift_stage0 = abs_shift_val[0] ? (in_data << 1) : in_data;
    assign left_shift_stage1 = abs_shift_val[1] ? (left_shift_stage0 << 2) : left_shift_stage0;
    assign left_shift_stage2 = abs_shift_val[2] ? (left_shift_stage1 << 4) : left_shift_stage1;
    assign left_shift_stage3 = abs_shift_val[3] ? (left_shift_stage2 << 8) : left_shift_stage2;
    assign left_shift_stage4 = abs_shift_val[4] ? (left_shift_stage3 << 16) : left_shift_stage3;

    // 桶形移位器右移
    wire [OUT_W-1:0] right_shift_stage0;
    wire [OUT_W-1:0] right_shift_stage1;
    wire [OUT_W-1:0] right_shift_stage2;
    wire [OUT_W-1:0] right_shift_stage3;
    wire [OUT_W-1:0] right_shift_stage4;

    assign right_shift_stage0 = abs_shift_val[0] ? (in_data >> 1) : in_data;
    assign right_shift_stage1 = abs_shift_val[1] ? (right_shift_stage0 >> 2) : right_shift_stage0;
    assign right_shift_stage2 = abs_shift_val[2] ? (right_shift_stage1 >> 4) : right_shift_stage1;
    assign right_shift_stage3 = abs_shift_val[3] ? (right_shift_stage2 >> 8) : right_shift_stage2;
    assign right_shift_stage4 = abs_shift_val[4] ? (right_shift_stage3 >> 16) : right_shift_stage3;

    assign shifted_result = shift_left ? left_shift_stage4 : right_shift_stage4;

endmodule

// 定点后处理模块
module fixed_postproc #(
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter MANT_W = 10,
    parameter EXP_W = 5
)(
    input  wire [MANT_W+INT_W+FRAC_W:0] shifted_result,
    input  wire sign_bit,
    output reg  [INT_W+FRAC_W-1:0] fixed_out,
    output wire overflow
);
    wire [INT_W+FRAC_W-1:0] abs_fixed;
    assign abs_fixed = shifted_result[INT_W+FRAC_W-1:0];
    assign overflow = |shifted_result[MANT_W+INT_W+FRAC_W:INT_W+FRAC_W];

    always @* begin
        fixed_out = sign_bit ? (~abs_fixed + 1'b1) : abs_fixed;
    end
endmodule