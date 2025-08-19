//SystemVerilog
`timescale 1ns / 1ps
module priority_display_codec (
    input clk, rst_n,
    input [23:0] rgb_data,
    input [7:0] mono_data,
    input [15:0] yuv_data,
    input [2:0] format_select, // 0:RGB, 1:MONO, 2:YUV, 3-7:Reserved
    input priority_override,  // High priority mode
    output reg [15:0] display_out,
    output reg format_valid
);
    // 寄存器输入信号
    reg [23:0] rgb_data_reg;
    reg [7:0] mono_data_reg;
    reg [15:0] yuv_data_reg;
    reg [2:0] format_select_reg;
    reg priority_override_reg;
    
    // 暂存转换后的数据
    reg [15:0] rgb_converted;
    reg [15:0] mono_converted;
    reg [15:0] yuv_converted;
    reg [2:0] active_fmt;
    reg data_valid_rgb, data_valid_mono, data_valid_yuv;
    
    // 第一级：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_data_reg <= 24'h0;
            mono_data_reg <= 8'h0;
            yuv_data_reg <= 16'h0;
            format_select_reg <= 3'b0;
            priority_override_reg <= 1'b0;
        end else begin
            rgb_data_reg <= rgb_data;
            mono_data_reg <= mono_data;
            yuv_data_reg <= yuv_data;
            format_select_reg <= format_select;
            priority_override_reg <= priority_override;
        end
    end
    
    // 第二级：预转换各个格式数据，并确定激活的格式
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_converted <= 16'h0;
            mono_converted <= 16'h0;
            yuv_converted <= 16'h0;
            active_fmt <= 3'b0;
            data_valid_rgb <= 1'b0;
            data_valid_mono <= 1'b0;
            data_valid_yuv <= 1'b0;
        end else begin
            // RGB转换逻辑（提前执行，不等待格式选择）
            rgb_converted <= {rgb_data_reg[23:19], rgb_data_reg[15:10], rgb_data_reg[7:3]};
            data_valid_rgb <= 1'b1;
            
            // MONO转换逻辑
            mono_converted <= {mono_data_reg, mono_data_reg};
            data_valid_mono <= 1'b1;
            
            // YUV传递逻辑
            yuv_converted <= yuv_data_reg;
            data_valid_yuv <= 1'b1;
            
            // 确定激活的格式 - 优化逻辑
            active_fmt <= priority_override_reg ? 3'b000 : format_select_reg;
        end
    end
    
    // 第三级：优化的多路复用选择逻辑，使用单个case语句
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            format_valid <= 1'b0;
        end else begin
            // 使用case语句代替if-else链，优化比较逻辑
            case (active_fmt)
                3'b000: begin // RGB mode
                    display_out <= rgb_converted;
                    format_valid <= data_valid_rgb;
                end
                3'b001: begin // Mono mode
                    display_out <= mono_converted;
                    format_valid <= data_valid_mono;
                end
                3'b010: begin // YUV mode 
                    display_out <= yuv_converted;
                    format_valid <= data_valid_yuv;
                end
                default: begin // 使用单一default捕获所有其他情况
                    display_out <= 16'h0000;
                    format_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule