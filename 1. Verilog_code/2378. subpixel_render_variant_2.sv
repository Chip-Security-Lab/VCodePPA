//SystemVerilog
module subpixel_render (
    input [7:0] px1, px2,
    output [7:0] px_out
);
    // 内部连线声明
    wire [9:0] px1_weighted;
    wire [9:0] combined_sum;
    
    // 实例化权重计算模块
    pixel_weighting px1_weight_inst (
        .pixel_in(px1),
        .weight(3),
        .pixel_weighted(px1_weighted)
    );
    
    // 实例化像素融合模块
    pixel_blending pixel_blend_inst (
        .weighted_pixel(px1_weighted),
        .normal_pixel(px2),
        .blended_result(combined_sum)
    );
    
    // 实例化输出缩放模块
    output_scaling output_scale_inst (
        .sum_in(combined_sum),
        .scaled_out(px_out)
    );
endmodule

// 像素权重计算模块
module pixel_weighting (
    input [7:0] pixel_in,
    input [2:0] weight,
    output [9:0] pixel_weighted
);
    // 用移位和加法实现乘法
    // 目前固定为3倍权重，但设计为参数化以提高可复用性
    assign pixel_weighted = (weight == 3) ? 
                            ({2'b00, pixel_in} + {1'b0, pixel_in, 1'b0}) : 
                            {2'b00, pixel_in};
endmodule

// 像素融合模块
module pixel_blending (
    input [9:0] weighted_pixel,
    input [7:0] normal_pixel,
    output [9:0] blended_result
);
    wire [9:0] extended_normal;
    
    // 扩展第二个像素以匹配位宽
    assign extended_normal = {2'b00, normal_pixel};
    
    // 计算加权混合
    assign blended_result = weighted_pixel + extended_normal;
endmodule

// 输出缩放模块
module output_scaling (
    input [9:0] sum_in,
    output [7:0] scaled_out
);
    // 右移2位实现除以4
    assign scaled_out = sum_in[9:2];
endmodule