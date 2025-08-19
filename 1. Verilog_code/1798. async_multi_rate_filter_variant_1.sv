//SystemVerilog
// 顶层模块
module async_multi_rate_filter #(
    parameter W = 10
)(
    input [W-1:0] fast_in,
    input [W-1:0] slow_in,
    input [3:0] alpha,  // Blend factor 0-15
    output [W-1:0] filtered_out
);
    // 内部连线定义
    wire [W+4-1:0] fast_scaled;
    wire [W+4-1:0] slow_scaled;
    wire [3:0] inverted_alpha;
    
    // 计算反向alpha值(16-alpha)
    alpha_inverter alpha_inv_inst (
        .alpha(alpha),
        .inverted_alpha(inverted_alpha)
    );
    
    // 对快速输入进行缩放
    signal_scaler #(
        .W(W)
    ) fast_scaler_inst (
        .signal_in(fast_in),
        .scale_factor(alpha),
        .scaled_out(fast_scaled)
    );
    
    // 对慢速输入进行缩放
    signal_scaler #(
        .W(W)
    ) slow_scaler_inst (
        .signal_in(slow_in),
        .scale_factor(inverted_alpha),
        .scaled_out(slow_scaled)
    );
    
    // 融合缩放后的信号
    signal_blender #(
        .W(W)
    ) blender_inst (
        .fast_scaled(fast_scaled),
        .slow_scaled(slow_scaled),
        .blended_out(filtered_out)
    );
    
endmodule

// Alpha反转子模块 - 使用先行借位减法器实现
module alpha_inverter (
    input [3:0] alpha,
    output [3:0] inverted_alpha
);
    // 先行借位减法器实现
    wire [3:0] minuend;      // 被减数
    wire [3:0] subtrahend;   // 减数
    wire [3:0] borrow;       // 借位信号
    wire [3:0] difference;   // 差
    
    // 固定16作为被减数
    assign minuend = 4'd16;
    assign subtrahend = alpha;
    
    // 生成借位信号
    assign borrow[0] = subtrahend[0];
    assign borrow[1] = subtrahend[1] | (subtrahend[0] & minuend[1]);
    assign borrow[2] = subtrahend[2] | (subtrahend[1] & minuend[2]) | (subtrahend[0] & minuend[1] & minuend[2]);
    assign borrow[3] = subtrahend[3] | (subtrahend[2] & minuend[3]) | (subtrahend[1] & minuend[2] & minuend[3]) | 
                      (subtrahend[0] & minuend[1] & minuend[2] & minuend[3]);
    
    // 计算每一位的差值
    assign difference[0] = minuend[0] ^ subtrahend[0];
    assign difference[1] = minuend[1] ^ borrow[0];
    assign difference[2] = minuend[2] ^ borrow[1];
    assign difference[3] = minuend[3] ^ borrow[2];
    
    // 将结果赋值给输出
    assign inverted_alpha = difference;
endmodule

// 信号缩放子模块
module signal_scaler #(
    parameter W = 10
)(
    input [W-1:0] signal_in,
    input [3:0] scale_factor,
    output [W+4-1:0] scaled_out
);
    // 注册计算结果以提高时序性能
    reg [W+4-1:0] scaled_out_reg;
    
    always @(*) begin
        scaled_out_reg = signal_in * scale_factor;
    end
    
    assign scaled_out = scaled_out_reg;
endmodule

// 信号混合子模块
module signal_blender #(
    parameter W = 10
)(
    input [W+4-1:0] fast_scaled,
    input [W+4-1:0] slow_scaled,
    output [W-1:0] blended_out
);
    // 注册计算结果以提高时序性能
    reg [W+4-1:0] sum_reg;
    reg [W-1:0] blended_out_reg;
    
    always @(*) begin
        sum_reg = fast_scaled + slow_scaled;
        blended_out_reg = sum_reg >> 4;
    end
    
    assign blended_out = blended_out_reg;
endmodule