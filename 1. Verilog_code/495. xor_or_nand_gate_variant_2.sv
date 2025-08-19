//SystemVerilog
`timescale 1ns / 1ps

module xor_or_nand_gate (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号，低电平有效
    input wire A, B, C,     // 输入A, B, C
    output reg Y            // 输出Y
);

    // 内部信号定义 - 优化数据路径
    reg xor_stage;          // 异或运算结果
    reg or_not_and_stage;   // 优化后的逻辑表达式结果
    
    // 第一级流水线 - 计算基本逻辑操作，应用布尔代数优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage <= 1'b0;
            or_not_and_stage <= 1'b0;
        end else begin
            // 异或运算保持不变
            xor_stage <= A ^ B;
            // ~(C & A) = ~C | ~A，应用德摩根定律
            or_not_and_stage <= ~C | ~A;
        end
    end
    
    // 第二级流水线 - 合并运算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xor_stage | or_not_and_stage;
        end
    end

endmodule