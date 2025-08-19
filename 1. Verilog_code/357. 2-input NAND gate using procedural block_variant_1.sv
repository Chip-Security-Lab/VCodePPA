//SystemVerilog
`timescale 1ns / 1ps

module nand2_3 (
    input  wire clk,     // 添加时钟输入以支持流水线结构
    input  wire rst_n,   // 添加复位信号以确保稳定初始化
    input  wire A,
    input  wire B,
    output wire Y
);
    // 内部信号定义，用于构建清晰的数据通路
    wire and_result;
    reg  stage1_a, stage1_b;
    reg  stage2_and;
    reg  stage3_nand;
    
    // 第一级流水线 - 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
        end
    end
    
    // 组合逻辑 - AND操作
    assign and_result = stage1_a & stage1_b;
    
    // 第二级流水线 - AND结果寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and <= 1'b0;
        end else begin
            stage2_and <= and_result;
        end
    end
    
    // 第三级流水线 - NAND结果寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_nand <= 1'b1; // NAND默认输出为1
        end else begin
            stage3_nand <= ~stage2_and;
        end
    end
    
    // 输出赋值
    assign Y = stage3_nand;
    
endmodule