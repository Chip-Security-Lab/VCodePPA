//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 顶层模块：YUV到RGB转换器
///////////////////////////////////////////////////////////////////////////////
module yuv_to_rgb_codec #(
    parameter Y_WIDTH = 8,
    parameter UV_WIDTH = 8
) (
    input [Y_WIDTH-1:0] y_in,
    input [UV_WIDTH-1:0] u_in, v_in,
    output [23:0] rgb_out
);
    // YUV偏移调整
    wire signed [15:0] c, d, e;
    yuv_offset_adjuster #(
        .Y_WIDTH(Y_WIDTH),
        .UV_WIDTH(UV_WIDTH)
    ) offset_adj (
        .y_in(y_in),
        .u_in(u_in),
        .v_in(v_in),
        .c_out(c),
        .d_out(d),
        .e_out(e)
    );
    
    // 颜色分量计算
    wire [15:0] r_calc, g_calc, b_calc;
    rgb_component_calculator rgb_calc (
        .c(c),
        .d(d),
        .e(e),
        .r_calc(r_calc),
        .g_calc(g_calc),
        .b_calc(b_calc)
    );
    
    // 颜色饱和度处理
    wire [7:0] r, g, b;
    rgb_saturation_handler sat_handler (
        .r_in(r_calc),
        .g_in(g_calc),
        .b_in(b_calc),
        .r_out(r),
        .g_out(g),
        .b_out(b)
    );
    
    // 输出RGB封装
    assign rgb_out = {r, g, b};
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块1：YUV偏移调整器 - 处理YUV输入的偏移调整
///////////////////////////////////////////////////////////////////////////////
module yuv_offset_adjuster #(
    parameter Y_WIDTH = 8,
    parameter UV_WIDTH = 8
) (
    input [Y_WIDTH-1:0] y_in,
    input [UV_WIDTH-1:0] u_in, v_in,
    output signed [15:0] c_out, d_out, e_out
);
    // 批量处理偏移调整，提高代码清晰度
    assign c_out = y_in - 16;
    assign d_out = u_in - 128;
    assign e_out = v_in - 128;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块2：RGB分量计算器 - 执行YUV到RGB的变换矩阵计算
///////////////////////////////////////////////////////////////////////////////
module rgb_component_calculator (
    input signed [15:0] c, d, e,
    output [15:0] r_calc, g_calc, b_calc
);
    // 使用常量乘法器优化 - 通过查找表实现
    localparam signed [15:0] C_MUL_298 = 298;
    localparam signed [15:0] E_MUL_409 = 409;
    localparam signed [15:0] D_MUL_100 = 100;
    localparam signed [15:0] E_MUL_208 = 208;
    localparam signed [15:0] D_MUL_516 = 516;
    localparam signed [15:0] ROUNDING = 128;
    
    // 乘法器实现 - 使用DSP资源更高效
    wire signed [31:0] c_mul_298 = c * C_MUL_298;
    wire signed [31:0] e_mul_409 = e * E_MUL_409;
    wire signed [31:0] d_mul_100 = d * D_MUL_100;
    wire signed [31:0] e_mul_208 = e * E_MUL_208;
    wire signed [31:0] d_mul_516 = d * D_MUL_516;
    
    // 共享乘法结果以减少资源使用
    wire signed [31:0] c_term = c_mul_298 + ROUNDING;
    
    // 计算并正确舍入
    assign r_calc = (c_term + e_mul_409) >>> 8;
    assign g_calc = (c_term - d_mul_100 - e_mul_208) >>> 8;
    assign b_calc = (c_term + d_mul_516) >>> 8;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块3：RGB饱和度处理器 - 处理颜色值的钳位，确保在0-255范围内
///////////////////////////////////////////////////////////////////////////////
module rgb_saturation_handler (
    input [15:0] r_in, g_in, b_in,
    output [7:0] r_out, g_out, b_out
);
    // 优化比较链，使用更有效的范围检查
    // 红色分量饱和处理
    assign r_out = (|r_in[15:8]) ? ((r_in[15]) ? 8'd0 : 8'd255) : r_in[7:0];
    
    // 绿色分量饱和处理
    assign g_out = (|g_in[15:8]) ? ((g_in[15]) ? 8'd0 : 8'd255) : g_in[7:0];
    
    // 蓝色分量饱和处理
    assign b_out = (|b_in[15:8]) ? ((b_in[15]) ? 8'd0 : 8'd255) : b_in[7:0];
    
endmodule