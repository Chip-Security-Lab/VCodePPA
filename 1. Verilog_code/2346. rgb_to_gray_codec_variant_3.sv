//SystemVerilog
// 顶层模块
module rgb_to_gray_codec #(
    parameter R_WEIGHT = 77,  // 0.299 * 256
    parameter G_WEIGHT = 150, // 0.587 * 256
    parameter B_WEIGHT = 29   // 0.114 * 256
) (
    input  wire [23:0] rgb_pixel,
    output wire [7:0]  gray_out
);
    // 信号定义
    wire [7:0] r_channel, g_channel, b_channel;
    wire [15:0] r_contrib, g_contrib, b_contrib;
    wire [15:0] sum_result;
    
    // 子模块实例化
    color_channel_splitter splitter_inst (
        .rgb_pixel(rgb_pixel),
        .r_channel(r_channel),
        .g_channel(g_channel),
        .b_channel(b_channel)
    );
    
    contribution_calculator contrib_calc_inst (
        .r_channel(r_channel),
        .g_channel(g_channel),
        .b_channel(b_channel),
        .r_weight(R_WEIGHT),
        .g_weight(G_WEIGHT),
        .b_weight(B_WEIGHT),
        .r_contrib(r_contrib),
        .g_contrib(g_contrib),
        .b_contrib(b_contrib)
    );
    
    weighted_sum_calculator sum_calc_inst (
        .r_contrib(r_contrib),
        .g_contrib(g_contrib),
        .b_contrib(b_contrib),
        .sum_result(sum_result)
    );
    
    normalized_output normalizer_inst (
        .sum_result(sum_result),
        .gray_out(gray_out)
    );
endmodule

// 子模块：颜色通道分离器
module color_channel_splitter (
    input  wire [23:0] rgb_pixel,
    output wire [7:0]  r_channel,
    output wire [7:0]  g_channel,
    output wire [7:0]  b_channel
);
    assign r_channel = rgb_pixel[23:16];
    assign g_channel = rgb_pixel[15:8];
    assign b_channel = rgb_pixel[7:0];
endmodule

// 子模块：贡献值计算器
module contribution_calculator (
    input  wire [7:0]  r_channel,
    input  wire [7:0]  g_channel,
    input  wire [7:0]  b_channel,
    input  wire [7:0]  r_weight,
    input  wire [7:0]  g_weight,
    input  wire [7:0]  b_weight,
    output wire [15:0] r_contrib,
    output wire [15:0] g_contrib,
    output wire [15:0] b_contrib
);
    assign r_contrib = r_weight * r_channel;
    assign g_contrib = g_weight * g_channel;
    assign b_contrib = b_weight * b_channel;
endmodule

// 子模块：加权和计算器
module weighted_sum_calculator (
    input  wire [15:0] r_contrib,
    input  wire [15:0] g_contrib,
    input  wire [15:0] b_contrib,
    output wire [15:0] sum_result
);
    assign sum_result = r_contrib + g_contrib + b_contrib;
endmodule

// 子模块：归一化输出
module normalized_output (
    input  wire [15:0] sum_result,
    output wire [7:0]  gray_out
);
    assign gray_out = sum_result >> 8;
endmodule