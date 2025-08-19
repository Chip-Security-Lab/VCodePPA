//SystemVerilog
// Top-level module: Hierarchical float-to-fixed-point conversion
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

    // Signal declarations for inter-module connections
    wire sign_bit;
    wire [EXP_W-1:0] exponent;
    wire [MANT_W-1:0] mantissa;
    wire [MANT_W:0] mantissa_full;
    wire signed [EXP_W:0] shift_amount;
    wire [MANT_W+INT_W+FRAC_W:0] shifted_mantissa;
    wire [INT_W+FRAC_W-1:0] abs_fixed_result;
    wire overflow_flag;

    // Floating-point input decoder
    float_input_decoder #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) u_input_decoder (
        .float_in    (float_in),
        .sign        (sign_bit),
        .exp         (exponent),
        .mant        (mantissa),
        .full_mant   (mantissa_full)
    );

    // Shift amount calculator
    shift_amount_calc #(
        .EXP_W(EXP_W),
        .FRAC_W(FRAC_W)
    ) u_shift_amount_calc (
        .exp        (exponent),
        .shift_amt  (shift_amount)
    );

    // Mantissa shifter (normalizes mantissa according to shift amount)
    mantissa_shifter #(
        .MANT_W(MANT_W),
        .INT_W(INT_W),
        .FRAC_W(FRAC_W)
    ) u_mantissa_shifter (
        .full_mant   (mantissa_full),
        .shift_amt   (shift_amount),
        .shifted     (shifted_mantissa)
    );

    // Overflow detector and absolute value extractor
    overflow_and_abs #(
        .MANT_W(MANT_W),
        .INT_W(INT_W),
        .FRAC_W(FRAC_W)
    ) u_overflow_and_abs (
        .shifted     (shifted_mantissa),
        .abs_result  (abs_fixed_result),
        .overflow    (overflow_flag)
    );

    // Sign applicator (handles two's complement for negative results)
    sign_applicator #(
        .INT_W(INT_W),
        .FRAC_W(FRAC_W)
    ) u_sign_applicator (
        .sign        (sign_bit),
        .abs_result  (abs_fixed_result),
        .fixed_out   (fixed_out)
    );

    assign overflow = overflow_flag;

endmodule

//-----------------------------------------------------------------------------
// 子模块: float_input_decoder
// 功能：解析输入的浮点数，分离出符号位、指数和尾数，并生成带隐含前导1的尾数
//-----------------------------------------------------------------------------
module float_input_decoder #(
    parameter EXP_W  = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output wire                  sign,
    output wire [EXP_W-1:0]      exp,
    output wire [MANT_W-1:0]     mant,
    output wire [MANT_W:0]       full_mant
);
    assign sign      = float_in[EXP_W+MANT_W];
    assign exp       = float_in[EXP_W+MANT_W-1:MANT_W];
    assign mant      = float_in[MANT_W-1:0];
    assign full_mant = {1'b1, mant}; // 隐含的前导1
endmodule

//-----------------------------------------------------------------------------
// 子模块: shift_amount_calc
// 功能：计算浮点转定点所需的移位量
// 合并所有与移位量相关的组合逻辑
//-----------------------------------------------------------------------------
module shift_amount_calc #(
    parameter EXP_W  = 5,
    parameter FRAC_W = 8
)(
    input  wire [EXP_W-1:0] exp,
    output reg  signed [EXP_W:0] shift_amt
);
    // Bias = 2^(EXP_W-1) - 1
    localparam [EXP_W-1:0] EXP_BIAS = {(EXP_W-1){1'b1}};
    always @* begin
        shift_amt = $signed({1'b0, exp}) - $signed({1'b0, EXP_BIAS}) - FRAC_W;
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块: mantissa_shifter
// 功能：根据移位量对尾数进行左移或右移，实现定点对齐
// 合并所有与移位相关的组合逻辑
//-----------------------------------------------------------------------------
module mantissa_shifter #(
    parameter MANT_W = 10,
    parameter INT_W  = 8,
    parameter FRAC_W = 8
)(
    input  wire [MANT_W:0]      full_mant,
    input  wire signed [($clog2(MANT_W+INT_W+FRAC_W+2))-1:0] shift_amt,
    output reg  [MANT_W+INT_W+FRAC_W:0] shifted
);
    localparam SHIFT_W = $clog2(MANT_W+INT_W+FRAC_W+2);

    always @* begin
        shifted = (shift_amt >= 0) ? (full_mant << shift_amt[SHIFT_W-1:0]) : (full_mant >> (-shift_amt[SHIFT_W-1:0]));
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块: overflow_and_abs
// 功能：检测溢出并提取定点结果的绝对值部分
// 合并所有相关组合逻辑
//-----------------------------------------------------------------------------
module overflow_and_abs #(
    parameter MANT_W = 10,
    parameter INT_W  = 8,
    parameter FRAC_W = 8
)(
    input  wire [MANT_W+INT_W+FRAC_W:0] shifted,
    output reg [INT_W+FRAC_W-1:0]      abs_result,
    output reg                         overflow
);
    always @* begin
        abs_result = shifted[INT_W+FRAC_W-1:0];
        overflow   = |shifted[MANT_W+INT_W+FRAC_W:INT_W+FRAC_W];
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块: sign_applicator
// 功能：根据符号位对定点结果进行符号扩展（正数原码，负数补码）
// 合并符号应用相关组合逻辑
//-----------------------------------------------------------------------------
module sign_applicator #(
    parameter INT_W  = 8,
    parameter FRAC_W = 8
)(
    input  wire              sign,
    input  wire [INT_W+FRAC_W-1:0] abs_result,
    output reg  [INT_W+FRAC_W-1:0] fixed_out
);
    always @* begin
        fixed_out = sign ? (~abs_result + 1'b1) : abs_result;
    end
endmodule