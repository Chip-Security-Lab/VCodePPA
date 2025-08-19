//SystemVerilog
//IEEE 1364-2005 标准
`timescale 1ns / 1ps

// 顶层模块 - 流水线版本
module basic_display_codec (
    input clk,                // 时钟信号
    input rst_n,              // 低电平有效复位
    input valid_in,           // 输入数据有效标志
    input [7:0] pixel_in,     // 8位输入像素
    output valid_out,         // 输出数据有效标志
    output [15:0] display_out // 16位输出显示数据
);
    // 第一级流水线信号
    reg valid_stage1;
    reg [7:0] pixel_stage1;
    
    // 第二级流水线信号
    reg valid_stage2;
    reg [4:0] red_stage2;
    reg [4:0] green_stage2;
    reg [5:0] blue_stage2;
    
    // 第三级流水线信号 (输出)
    reg valid_stage3;
    reg [15:0] display_stage3;
    
    // 内部连接信号
    wire [4:0] red_component;
    wire [4:0] green_component;
    wire [5:0] blue_component;
    
    // 颜色分量提取子模块
    pixel_color_extractor extractor (
        .pixel_in(pixel_stage1),
        .red_component(red_component),
        .green_component(green_component),
        .blue_component(blue_component)
    );
    
    // 第一级流水线 - 寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            pixel_stage1 <= 8'h00;
        end
        else begin
            valid_stage1 <= valid_in;
            pixel_stage1 <= pixel_in;
        end
    end
    
    // 第二级流水线 - 存储颜色分量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            red_stage2 <= 5'h00;
            green_stage2 <= 5'h00;
            blue_stage2 <= 6'h00;
        end
        else begin
            valid_stage2 <= valid_stage1;
            red_stage2 <= red_component;
            green_stage2 <= green_component;
            blue_stage2 <= blue_component;
        end
    end
    
    // 第三级流水线 - 生成显示输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            display_stage3 <= 16'h0000;
        end
        else begin
            valid_stage3 <= valid_stage2;
            display_stage3 <= {red_stage2, green_stage2, blue_stage2};
        end
    end
    
    // 输出赋值
    assign valid_out = valid_stage3;
    assign display_out = display_stage3;
    
endmodule

// 颜色分量提取子模块
module pixel_color_extractor (
    input [7:0] pixel_in,          // 输入像素
    output [4:0] red_component,    // 红色分量
    output [4:0] green_component,  // 绿色分量
    output [5:0] blue_component    // 蓝色分量
);
    // 从输入像素中提取RGB颜色分量
    assign red_component = {pixel_in[7:5], 2'b00};  // 提取红色并扩展
    assign green_component = {pixel_in[4:2], 2'b00}; // 提取绿色并扩展
    assign blue_component = {pixel_in[1:0], 4'b0000}; // 提取蓝色并扩展
    
endmodule