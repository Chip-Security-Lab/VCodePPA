//SystemVerilog
//IEEE 1364-2005 Verilog标准
`timescale 1ns / 1ps
module error_diffusion (
    input clk,
    input rst_n,         // 添加复位信号
    input valid_in,      // 输入有效信号
    input [7:0] in,
    output reg valid_out,// 输出有效信号  
    output reg [3:0] out
);
    // 流水线阶段1: 输入和初始处理阶段
    reg [7:0] in_stage1;
    reg [11:0] err_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 计算阶段
    reg [11:0] sum_stage2;
    reg valid_stage2;
    
    // 流水线阶段3: 输出和误差计算阶段
    wire [3:0] out_stage3;
    wire [11:0] new_err_stage3;
    
    // 流水线阶段1: 输入寄存和误差存储
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_stage1 <= 8'h0;
            err_stage1 <= 12'h0;
            valid_stage1 <= 1'b0;
        end else begin
            in_stage1 <= in;
            err_stage1 <= (valid_out) ? new_err_stage3 : err_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2: 计算和寄存中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 12'h0;
            valid_stage2 <= 1'b0;
        end else begin
            sum_stage2 <= in_stage1 + err_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3的组合逻辑计算
    assign out_stage3 = sum_stage2[11:8];
    assign new_err_stage3 = (sum_stage2 << 4) - ({out_stage3, 8'b0});
    
    // 流水线阶段3: 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 4'h0;
            valid_out <= 1'b0;
        end else begin
            out <= out_stage3;
            valid_out <= valid_stage2;
        end
    end
endmodule