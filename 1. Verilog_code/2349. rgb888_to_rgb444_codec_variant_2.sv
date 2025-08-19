//SystemVerilog
module rgb888_to_rgb444_codec (
    input clk, rst,
    input [23:0] rgb888_in,
    input dither_en,
    input [3:0] dither_seed,
    output reg [11:0] rgb444_out
);
    // LFSR寄存器及中间值定义
    reg [3:0] lfsr_current, lfsr_next;
    reg lfsr_dither_bit;
    
    // 分离的RGB通道信号 - 流水线第一级
    reg [3:0] r_msb, g_msb, b_msb;
    reg [3:0] r_lsb, g_lsb, b_lsb;
    
    // 阈值比较结果 - 流水线第二级
    reg r_threshold_met, g_threshold_met, b_threshold_met;
    
    // 增量计算 - 流水线第三级
    reg [3:0] r_increment, g_increment, b_increment;
    
    // 输出寄存器 - 最终流水线级
    reg [3:0] r_out, g_out, b_out;
    wire [3:0] r_combined, g_combined, b_combined;
    
    // LFSR更新逻辑 - 分离的组合逻辑
    always @(*) begin
        if (dither_en)
            lfsr_next = {lfsr_current[2:0], lfsr_current[3] ^ lfsr_current[2]};
        else
            lfsr_next = lfsr_current;
    end
    
    // RGB分离 - 第一级流水线阶段逻辑
    always @(posedge clk) begin
        if (rst) begin
            lfsr_current <= dither_seed;
            lfsr_dither_bit <= 1'b0;
            
            // 初始化RGB通道分离寄存器
            r_msb <= 4'h0;
            g_msb <= 4'h0;
            b_msb <= 4'h0;
            r_lsb <= 4'h0;
            g_lsb <= 4'h0;
            b_lsb <= 4'h0;
        end
        else begin
            lfsr_current <= lfsr_next;
            lfsr_dither_bit <= lfsr_current[0];
            
            // 捕获输入RGB数据的高位和低位部分
            r_msb <= rgb888_in[23:20];
            g_msb <= rgb888_in[15:12];
            b_msb <= rgb888_in[7:4];
            
            r_lsb <= rgb888_in[19:16];
            g_lsb <= rgb888_in[11:8];
            b_lsb <= rgb888_in[3:0];
        end
    end
    
    // 阈值判断 - 第二级流水线阶段逻辑
    always @(posedge clk) begin
        if (rst) begin
            r_threshold_met <= 1'b0;
            g_threshold_met <= 1'b0;
            b_threshold_met <= 1'b0;
        end
        else begin
            r_threshold_met <= (r_lsb > 4'h8);
            g_threshold_met <= (g_lsb > 4'h8);
            b_threshold_met <= (b_lsb > 4'h8);
        end
    end
    
    // 增量计算 - 第三级流水线阶段逻辑
    always @(posedge clk) begin
        if (rst) begin
            r_increment <= 4'h0;
            g_increment <= 4'h0;
            b_increment <= 4'h0;
        end
        else begin
            r_increment <= r_msb;
            g_increment <= g_msb;
            b_increment <= b_msb;
        end
    end
    
    // 组合逻辑 - 计算最终RGB输出值
    assign r_combined = r_increment + (dither_en & lfsr_dither_bit & r_threshold_met);
    assign g_combined = g_increment + (dither_en & lfsr_dither_bit & g_threshold_met);
    assign b_combined = b_increment + (dither_en & lfsr_dither_bit & b_threshold_met);
    
    // 输出寄存器 - 最终流水线级
    always @(posedge clk) begin
        if (rst) begin
            r_out <= 4'h0;
            g_out <= 4'h0;
            b_out <= 4'h0;
            rgb444_out <= 12'h000;
        end
        else begin
            r_out <= r_combined;
            g_out <= g_combined;
            b_out <= b_combined;
            rgb444_out <= {r_out, g_out, b_out};
        end
    end
    
    // 公开dither_bit供可能的外部使用
    wire dither_bit;
    assign dither_bit = lfsr_dither_bit;
    
endmodule