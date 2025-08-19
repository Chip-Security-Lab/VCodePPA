//SystemVerilog
// 顶层模块
module rgb2yuv (
    input [7:0] r, g, b,
    output [7:0] y, u, v
);
    // 内部连线
    wire [15:0] y_temp, u_temp, v_temp;
    
    // 子模块实例化
    y_calculator y_calc (
        .r(r),
        .g(g),
        .b(b),
        .y_temp(y_temp)
    );
    
    u_calculator u_calc (
        .r(r),
        .g(g),
        .b(b),
        .u_temp(u_temp)
    );
    
    v_calculator v_calc (
        .r(r),
        .g(g),
        .b(b),
        .v_temp(v_temp)
    );
    
    output_scaler scaler (
        .y_temp(y_temp),
        .u_temp(u_temp),
        .v_temp(v_temp),
        .y(y),
        .u(u),
        .v(v)
    );
    
endmodule

// Y分量计算子模块
module y_calculator (
    input [7:0] r, g, b,
    output [15:0] y_temp
);
    // Y = 0.257*R + 0.504*G + 0.098*B + 16
    // Scaled as: Y = (66*R + 129*G + 25*B + 128) >> 8
    assign y_temp = 129*g + 66*r + 25*b + 128;
endmodule

// U分量计算子模块
module u_calculator (
    input [7:0] r, g, b,
    output [15:0] u_temp
);
    // U = -0.148*R - 0.291*G + 0.439*B + 128
    // Scaled as: U = (112*B - 38*R - 74*G + 128) >> 8
    assign u_temp = 112*b - 38*r - 74*g + 128;
endmodule

// V分量计算子模块
module v_calculator (
    input [7:0] r, g, b,
    output [15:0] v_temp
);
    // V = 0.439*R - 0.368*G - 0.071*B + 128
    // Scaled as: V = (112*R - 94*G - 18*B + 128) >> 8
    assign v_temp = 112*r - 94*g - 18*b + 128;
endmodule

// 输出缩放子模块
module output_scaler (
    input [15:0] y_temp, u_temp, v_temp,
    output [7:0] y, u, v
);
    // 取高8位作为最终输出（相当于右移8位）
    assign y = y_temp[15:8];
    assign u = u_temp[15:8];
    assign v = v_temp[15:8];
endmodule