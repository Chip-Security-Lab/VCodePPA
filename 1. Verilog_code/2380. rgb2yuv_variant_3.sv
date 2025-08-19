//SystemVerilog
module rgb2yuv (
    input wire clk,           // Clock signal for pipeline
    input wire rst_n,         // Reset signal
    input wire [7:0] r, g, b, // RGB input components
    output reg [7:0] y, u, v  // YUV output components (registered)
);

    // ==================== 数据流水线阶段定义 ====================
    // 阶段1: 输入寄存器
    reg [7:0] r_pipe1, g_pipe1, b_pipe1;
    
    // 阶段2: 系数乘法计算
    // Y 通道计算路径
    reg [15:0] y_r_coeff, y_g_coeff, y_b_coeff;
    
    // U 通道计算路径
    reg [15:0] u_r_coeff, u_g_coeff, u_b_coeff;
    
    // V 通道计算路径
    reg [15:0] v_r_coeff, v_g_coeff, v_b_coeff;
    
    // 阶段3: 中间加法和偏置
    reg [15:0] y_sum_pipe3;
    reg [15:0] u_sum_pipe3;
    reg [15:0] v_sum_pipe3;
    
    // ==================== 流水线实现 ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            // 阶段1: 输入寄存
            r_pipe1 <= 8'b0;
            g_pipe1 <= 8'b0;
            b_pipe1 <= 8'b0;
            
            // 阶段2: 系数乘法
            y_r_coeff <= 16'b0;
            y_g_coeff <= 16'b0;
            y_b_coeff <= 16'b0;
            
            u_r_coeff <= 16'b0;
            u_g_coeff <= 16'b0;
            u_b_coeff <= 16'b0;
            
            v_r_coeff <= 16'b0;
            v_g_coeff <= 16'b0;
            v_b_coeff <= 16'b0;
            
            // 阶段3: 中间求和
            y_sum_pipe3 <= 16'b0;
            u_sum_pipe3 <= 16'b0;
            v_sum_pipe3 <= 16'b0;
            
            // 阶段4: 输出
            y <= 8'b0;
            u <= 8'b0;
            v <= 8'b0;
        end
        else begin
            // ===== 阶段1: 缓存输入RGB值 =====
            r_pipe1 <= r;
            g_pipe1 <= g;
            b_pipe1 <= b;
            
            // ===== 阶段2: 并行计算所有系数乘法 =====
            // Y = 0.257*R + 0.504*G + 0.098*B + 16
            // 系数放大256倍: 66R + 129G + 25B + 128
            y_r_coeff <= r_pipe1 * 16'd66;
            y_g_coeff <= g_pipe1 * 16'd129;
            y_b_coeff <= b_pipe1 * 16'd25;
            
            // U = -0.148*R - 0.291*G + 0.439*B + 128
            // 系数放大256倍: -38R - 74G + 112B + 128
            u_r_coeff <= r_pipe1 * 16'd38;  // 将在下一阶段取负
            u_g_coeff <= g_pipe1 * 16'd74;  // 将在下一阶段取负
            u_b_coeff <= b_pipe1 * 16'd112;
            
            // V = 0.439*R - 0.368*G - 0.071*B + 128
            // 系数放大256倍: 112R - 94G - 18B + 128
            v_r_coeff <= r_pipe1 * 16'd112;
            v_g_coeff <= g_pipe1 * 16'd94;  // 将在下一阶段取负
            v_b_coeff <= b_pipe1 * 16'd18;  // 将在下一阶段取负
            
            // ===== 阶段3: 计算各通道的总和并添加偏置 =====
            // Y通道求和
            y_sum_pipe3 <= y_r_coeff + y_g_coeff + y_b_coeff + 16'd128;
            
            // U通道求和 (应用负号)
            u_sum_pipe3 <= u_b_coeff - u_r_coeff - u_g_coeff + 16'd128;
            
            // V通道求和 (应用负号)
            v_sum_pipe3 <= v_r_coeff - v_g_coeff - v_b_coeff + 16'd128;
            
            // ===== 阶段4: 缩放结果并输出 =====
            // 移位右移8位 (相当于除以256) 并截断到8位
            y <= y_sum_pipe3[15:8];
            u <= u_sum_pipe3[15:8];
            v <= v_sum_pipe3[15:8];
        end
    end

endmodule