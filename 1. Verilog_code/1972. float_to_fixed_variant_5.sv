//SystemVerilog
module float_to_fixed #(
    parameter INT_W = 8,
    parameter FRAC_W = 8,
    parameter EXP_W = 5,
    parameter MANT_W = 10
)(
    input  wire [EXP_W+MANT_W:0] float_in,
    output reg  [INT_W+FRAC_W-1:0] fixed_out,
    output reg  overflow
);

    // 分解输入
    wire sign_bit;
    wire [EXP_W-1:0] exp_bits;
    wire [MANT_W-1:0] mantissa_bits;
    wire [MANT_W:0] mantissa_full;

    assign sign_bit      = float_in[EXP_W+MANT_W];
    assign exp_bits      = float_in[EXP_W+MANT_W-1:MANT_W];
    assign mantissa_bits = float_in[MANT_W-1:0];
    assign mantissa_full = {1'b1, mantissa_bits};

    // 常量
    localparam [EXP_W-1:0] EXP_BIAS     = {(EXP_W-1){1'b1}};
    localparam [EXP_W:0]   EXP_BIAS_EXT = {1'b0, EXP_BIAS};

    // 中间变量
    reg signed [EXP_W:0] shift_amount;
    reg [MANT_W+INT_W+FRAC_W:0] mantissa_shifted;
    reg [INT_W+FRAC_W-1:0] magnitude_result;

    // 条件中间变量
    reg shift_amt_non_neg;
    reg mantissa_nonzero;
    reg [MANT_W+INT_W+FRAC_W:0] mantissa_shifted_tmp;
    reg [MANT_W+INT_W+FRAC_W:0] mantissa_shifted_left;
    reg [MANT_W+INT_W+FRAC_W:0] mantissa_shifted_right;

    // 跳跃进位加法器8位实例
    wire [7:0] lca_a;
    wire [7:0] lca_b;
    wire lca_cin;
    wire [7:0] lca_sum;
    wire lca_cout;

    assign lca_a = ~magnitude_result;
    assign lca_b = 8'b0;
    assign lca_cin = 1'b1;

    lca_adder_8bit u_lca_adder_8bit (
        .a(lca_a),
        .b(lca_b),
        .cin(lca_cin),
        .sum(lca_sum),
        .cout(lca_cout)
    );

    always @* begin
        // 计算移位量
        shift_amount = {1'b0, exp_bits} - EXP_BIAS_EXT - FRAC_W;

        // 简化移位条件结构
        shift_amt_non_neg = (shift_amount[EXP_W] == 1'b0);

        // 左移与右移
        if (shift_amt_non_neg) begin
            mantissa_shifted_left  = mantissa_full << shift_amount[EXP_W-1:0];
            mantissa_shifted_right = { (MANT_W+INT_W+FRAC_W+1){1'b0} };
        end else begin
            mantissa_shifted_left  = { (MANT_W+INT_W+FRAC_W+1){1'b0} };
            mantissa_shifted_right = mantissa_full >> (~shift_amount + 1'b1);
        end

        // 选择最终移位结果
        if (shift_amt_non_neg)
            mantissa_shifted_tmp = mantissa_shifted_left;
        else
            mantissa_shifted_tmp = mantissa_shifted_right;
        mantissa_shifted = mantissa_shifted_tmp;

        // 溢出判断
        overflow = |mantissa_shifted[MANT_W+INT_W+FRAC_W:INT_W+FRAC_W];

        // 取有效位
        magnitude_result = mantissa_shifted[INT_W+FRAC_W-1:0];

        // 判断magnitude是否为非零
        mantissa_nonzero = |magnitude_result;

        // 输出补码/原码，利用跳跃进位加法器
        if (sign_bit && mantissa_nonzero)
            fixed_out = lca_sum;
        else
            fixed_out = magnitude_result;
    end
endmodule

// 跳跃进位加法器 8位
module lca_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] p, g;
    wire [7:0] c;

    assign p = a ^ b;
    assign g = a & b;

    // 跳跃进位链
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign cout = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum = p ^ c[7:0];
endmodule