//SystemVerilog - IEEE 1364-2005
`timescale 1ns/1ps

// 顶层模块 - 重构后的延迟XNOR模块
module Delay_XNOR (
    input  wire       clk,    // 添加时钟输入
    input  wire       rst_n,  // 添加复位信号
    input  wire       a,      // 第一个输入信号
    input  wire       b,      // 第二个输入信号
    output wire       z       // 输出信号
);
    // 内部流水线寄存器信号
    reg a_reg, b_reg;           // 输入寄存器级
    reg xnor_result_reg;        // XNOR结果寄存器级
    reg delay_stage1_reg;       // 延迟流水线第一级
    reg delay_stage2_reg;       // 延迟流水线第二级
    
    // 输入寄存器级 - 将输入信号缓存以提高时序性能
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // XNOR组合逻辑 + 寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            xnor_result_reg <= 1'b0;
        end else begin
            xnor_result_reg <= ~(a_reg ^ b_reg); // XNOR操作
        end
    end
    
    // 延迟流水线阶段1
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            delay_stage1_reg <= 1'b0;
        end else begin
            delay_stage1_reg <= xnor_result_reg;
        end
    end
    
    // 延迟流水线阶段2
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            delay_stage2_reg <= 1'b0;
        end else begin
            delay_stage2_reg <= delay_stage1_reg;
        end
    end
    
    // 最终输出
    assign z = delay_stage2_reg;
    
endmodule