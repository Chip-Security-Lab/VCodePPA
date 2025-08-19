//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module xor_nand_gate (
    input wire clk,        // 时钟输入
    input wire rst_n,      // 异步复位，低电平有效
    input wire A, B, C,    // 输入A, B, C
    output reg Y           // 输出Y
);
    // 内部信号定义 - 优化为更明确的命名
    reg xor_result_r;      // 第一级流水线：A与B的XOR结果
    reg c_inverted_r;      // 第一级流水线：C取反结果
    
    // 优化第一级流水线逻辑 - 用非阻塞赋值确保同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位值明确设置
            xor_result_r <= 1'b0;
            c_inverted_r <= 1'b0;
        end else begin
            // 直接计算并寄存结果
            xor_result_r <= A ^ B;
            c_inverted_r <= ~C;
        end
    end
    
    // 优化第二级流水线 - 简化逻辑并确保清晰的数据流
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            // 使用位与操作而非逻辑与，更适合硬件实现
            Y <= xor_result_r & c_inverted_r;
        end
    end
    
endmodule

`default_nettype wire