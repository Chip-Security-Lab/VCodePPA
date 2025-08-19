//SystemVerilog
//===================================================================
// Module: nand_or_xnor_gate
// Description: Optimized datapath with forward register retiming
//===================================================================

`timescale 1ns / 1ps

module nand_or_xnor_gate (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号，低电平有效
    input wire A, B, C,    // 输入A, B, C
    output reg Y           // 输出Y - 寄存器输出
);
    // 输入寄存器移除，直接使用组合逻辑
    wire nand_result;      // 与非操作的组合逻辑结果
    wire xnor_result;      // 同或操作的组合逻辑结果
    
    // 组合逻辑计算
    assign nand_result = ~(A & B);   // 与非操作
    assign xnor_result = ~(A ^ C);   // 同或操作
    
    // 中间结果寄存器 - 已将寄存器从输入端移到组合逻辑之后
    reg nand_result_r;
    reg xnor_result_r;
    
    // 移动到组合逻辑之后的寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result_r <= 1'b0;
            xnor_result_r <= 1'b0;
        end
        else begin
            nand_result_r <= nand_result;
            xnor_result_r <= xnor_result;
        end
    end
    
    // 第二级流水线保持不变
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end
        else begin
            Y <= nand_result_r | xnor_result_r;  // 或操作
        end
    end
    
endmodule