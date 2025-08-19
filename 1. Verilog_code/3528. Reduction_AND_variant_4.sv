//SystemVerilog
//IEEE 1364-2005 Verilog标准
`timescale 1ns / 1ps

module Reduction_AND_Top(
    input clk,                 // 时钟信号
    input rst_n,               // 复位信号，低电平有效
    input [7:0] data,          // 数据输入
    input valid,               // 输入数据有效信号
    output ready,              // 准备接收输入数据信号
    output reg [0:0] result,   // 结果输出
    output reg result_valid    // 输出结果有效信号
);
    // 内部信号
    reg [7:0] data_reg;        // 寄存输入数据
    reg processing_r;          // 优化为单比特寄存器
    wire result_ready;         // 指示结果准备好
    wire and_result;           // 并行计算结果
    
    // 准备接收新数据的条件：简化条件逻辑，优化关键路径
    assign ready = ~processing_r | result_valid;
    
    // 并行计算与运算结果，减少层级深度
    assign and_result = &data_reg;
    
    // 指示结果已准备好
    assign result_ready = processing_r & ~result_valid;
    
    // 寄存输入数据和状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
            processing_r <= 1'b0;
            result_valid <= 1'b0;
            result <= 1'b0;
        end
        else begin
            // 输入握手成功时，寄存数据并开始处理
            if (valid & ready) begin
                data_reg <= data;
                processing_r <= 1'b1;
                result_valid <= 1'b0;
            end
            
            // 处理完成时，更新结果并置位有效标志
            if (result_ready) begin
                result <= and_result;
                result_valid <= 1'b1;
                processing_r <= 1'b0;
            end
        end
    end
endmodule