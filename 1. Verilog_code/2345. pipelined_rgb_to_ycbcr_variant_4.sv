//SystemVerilog
module pipelined_rgb_to_ycbcr (
    input clk, rst_n,
    input [23:0] rgb_in,
    input data_valid,
    output reg [23:0] ycbcr_out,
    output reg out_valid
);
    // Stage 1 - Input registers
    reg [23:0] rgb_stage1;
    reg valid_stage1;
    
    // 将计算分解为多个阶段的中间寄存器
    reg [15:0] r_factor, g_factor, b_factor;      // 第一阶段乘法结果
    reg [15:0] y_sum_stage2, cb_sum_stage2, cr_sum_stage2; // 第二阶段加法结果
    reg valid_stage1_5, valid_stage2, valid_stage2_5;
    
    // Stage 3 - 颜色分量寄存器
    reg [7:0] y_stage3, cb_stage3, cr_stage3;
    reg valid_stage3;
    
    // R,G,B分量提取
    wire [7:0] r = rgb_stage1[23:16];
    wire [7:0] g = rgb_stage1[15:8];
    wire [7:0] b = rgb_stage1[7:0];
    
    // 用于移位的寄存器和信号
    reg [15:0] y_shifted, cb_shifted, cr_shifted;
    reg [15:0] y_temp, cb_temp, cr_temp;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            rgb_stage1 <= 0; valid_stage1 <= 0;
            r_factor <= 0; g_factor <= 0; b_factor <= 0;
            valid_stage1_5 <= 0;
            y_sum_stage2 <= 0; cb_sum_stage2 <= 0; cr_sum_stage2 <= 0;
            valid_stage2 <= 0;
            y_shifted <= 0; cb_shifted <= 0; cr_shifted <= 0;
            valid_stage2_5 <= 0;
            y_stage3 <= 0; cb_stage3 <= 0; cr_stage3 <= 0;
            valid_stage3 <= 0;
            ycbcr_out <= 0; out_valid <= 0;
        end else begin
            // Pipeline stage 1: Register inputs
            rgb_stage1 <= rgb_in;
            valid_stage1 <= data_valid;
            
            // Pipeline stage 1.5: 计算各个因子 (拆分长组合路径)
            if (valid_stage1) begin
                // Y分量计算的乘法
                r_factor <= 16'd66 * r;
                g_factor <= 16'd129 * g;
                b_factor <= 16'd25 * b;
            end
            valid_stage1_5 <= valid_stage1;
            
            // Pipeline stage 2: 计算求和
            if (valid_stage1_5) begin
                // 计算求和部分
                y_sum_stage2 <= r_factor + g_factor + b_factor + 16'd128;
                cb_sum_stage2 <= 16'd38 * (r ^ 8'hFF) + 16'd74 * (g ^ 8'hFF) + 16'd112 * b + 16'd128;
                cr_sum_stage2 <= 16'd112 * r + 16'd94 * (g ^ 8'hFF) + 16'd18 * (b ^ 8'hFF) + 16'd128;
            end
            valid_stage2 <= valid_stage1_5;
            
            // Pipeline stage 2.5: 移位操作
            if (valid_stage2) begin
                // 移位 (相当于除以256)
                y_shifted <= {8'b0, y_sum_stage2[15:8]};
                cb_shifted <= {8'b0, cb_sum_stage2[15:8]};
                cr_shifted <= {8'b0, cr_sum_stage2[15:8]};
                
                // 计算最终值
                y_temp <= y_sum_stage2 >> 8;
                cb_temp <= cb_sum_stage2 >> 8;
                cr_temp <= cr_sum_stage2 >> 8;
            end
            valid_stage2_5 <= valid_stage2;
            
            // Pipeline stage 3: 饱和处理
            if (valid_stage2_5) begin
                // Y 分量饱和处理
                if (y_temp > 255 - 16) begin
                    y_stage3 <= 255;
                end else begin
                    y_stage3 <= y_temp[7:0] + 16;
                end
                
                // Cb 分量饱和处理
                if (cb_temp > 255 - 128) begin
                    cb_stage3 <= 255;
                end else begin
                    cb_stage3 <= cb_temp[7:0] + 128;
                end
                
                // Cr 分量饱和处理
                if (cr_temp > 255 - 128) begin
                    cr_stage3 <= 255;
                end else begin
                    cr_stage3 <= cr_temp[7:0] + 128;
                end
            end
            valid_stage3 <= valid_stage2_5;
            
            // Pipeline stage 4: Output
            ycbcr_out <= {y_stage3, cb_stage3, cr_stage3};
            out_valid <= valid_stage3;
        end
    end
endmodule