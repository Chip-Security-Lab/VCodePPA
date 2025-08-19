//SystemVerilog
// 顶层模块
module saturating_shifter (
    input [7:0] din,
    input [2:0] shift,
    output [7:0] dout
);
    // 控制信号
    wire use_saturated_value;
    wire [7:0] shifted_value;
    wire [7:0] saturated_value;

    // 子模块实例化
    shift_controller u_shift_controller (
        .shift(shift),
        .use_saturated_value(use_saturated_value)
    );

    // 替换简单的移位操作为基于Karatsuba算法的乘法
    karatsuba_multiplier u_shift_operator (
        .din(din),
        .shift(shift),
        .result(shifted_value)
    );

    saturator u_saturator (
        .saturated_value(saturated_value)
    );

    output_selector u_output_selector (
        .shifted_value(shifted_value),
        .saturated_value(saturated_value),
        .use_saturated_value(use_saturated_value),
        .dout(dout)
    );
endmodule

// 移位控制器子模块 - 决定是否使用饱和值
module shift_controller (
    input [2:0] shift,
    output reg use_saturated_value
);
    always @* begin
        use_saturated_value = (shift > 3'd5);
    end
endmodule

// Karatsuba乘法器 - 使用递归Karatsuba算法实现乘法
module karatsuba_multiplier (
    input [7:0] din,
    input [2:0] shift,
    output [7:0] result
);
    wire [7:0] multiplier;
    
    // 根据shift值生成乘数
    assign multiplier = (8'd1 << shift);
    
    // 内部信号定义
    wire [15:0] full_result;
    
    // 实现Karatsuba乘法
    karatsuba_8bit k_mult (
        .a(din),
        .b(multiplier),
        .result(full_result)
    );
    
    // 取低8位作为结果
    assign result = full_result[7:0];
endmodule

// 递归Karatsuba 8位乘法器
module karatsuba_8bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] result
);
    // 将8位数分解为高低各4位
    wire [3:0] a_high, a_low, b_high, b_low;
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // 计算三个乘积
    wire [7:0] z0, z1, z2;
    karatsuba_4bit k_low (
        .a(a_low),
        .b(b_low),
        .result(z0)
    );
    
    karatsuba_4bit k_high (
        .a(a_high),
        .b(b_high),
        .result(z2)
    );
    
    wire [3:0] a_sum, b_sum;
    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;
    
    wire [7:0] z1_full;
    karatsuba_4bit k_mid (
        .a(a_sum),
        .b(b_sum),
        .result(z1_full)
    );
    
    assign z1 = z1_full - z2 - z0;
    
    // 计算最终结果
    assign result = {z2, 8'b0} + {z1, 4'b0} + z0;
endmodule

// 4位Karatsuba乘法器
module karatsuba_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] result
);
    // 将4位数分解为高低各2位
    wire [1:0] a_high, a_low, b_high, b_low;
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // 计算三个乘积
    wire [3:0] z0, z1, z2;
    
    // 2位乘法直接计算
    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    
    wire [1:0] a_sum, b_sum;
    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;
    
    wire [3:0] z1_full;
    assign z1_full = a_sum * b_sum;
    assign z1 = z1_full - z2 - z0;
    
    // 计算最终结果
    assign result = {z2, 4'b0} + {z1, 2'b0} + z0;
endmodule

// 饱和值生成子模块
module saturator (
    output [7:0] saturated_value
);
    assign saturated_value = 8'hFF;
endmodule

// 输出选择器子模块 - 根据条件选择输出值
module output_selector (
    input [7:0] shifted_value,
    input [7:0] saturated_value,
    input use_saturated_value,
    output reg [7:0] dout
);
    always @* begin
        dout = use_saturated_value ? saturated_value : shifted_value;
    end
endmodule