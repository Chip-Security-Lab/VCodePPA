//SystemVerilog
`timescale 1ns/1ns

module Delay_AND (
    input  wire       clk,    // 时钟输入，用于寄存器同步
    input  wire       rst_n,  // 复位信号，低电平有效
    input  wire       a,      // 输入信号a
    input  wire       b,      // 输入信号b
    output reg        z       // 输出信号z
);

    // 内部流水线寄存器
    reg a_stage1, b_stage1;   // 第一级流水线寄存器
    reg and_result;           // 第二级流水线寄存器存储AND结果
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // 第二级流水线 - 计算AND逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
        end else begin
            and_result <= a_stage1 & b_stage1;
        end
    end
    
    // 第三级流水线 - 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z <= 1'b0;
        end else begin
            z <= and_result;
        end
    end

endmodule