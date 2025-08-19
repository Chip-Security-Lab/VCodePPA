//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

// 顶层模块 - 带Valid-Ready握手协议的Reduction AND
module Reduction_AND (
    input  wire        clk,         // 时钟信号
    input  wire        rst_n,       // 复位信号，低电平有效
    input  wire [7:0]  data,        // 输入数据
    input  wire        valid_in,    // 输入数据有效信号
    output wire        ready_out,   // 输出就绪信号
    output wire        valid_out,   // 输出数据有效信号
    input  wire        ready_in,    // 接收方就绪信号
    output wire        result       // 与运算结果
);

    // 中间信号
    wire [3:0] partial_and_low;
    wire [3:0] partial_and_high;
    wire       stage1_result_low;
    wire       stage1_result_high;
    wire       internal_result;
    
    // 状态寄存器
    reg        result_valid;
    reg [7:0]  data_reg;
    reg        result_reg;
    
    // 握手控制逻辑
    assign ready_out = ~result_valid | ready_in;
    assign valid_out = result_valid;
    
    // 注册数据和控制握手
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            result_valid <= 1'b0;
            data_reg <= 8'b0;
            result_reg <= 1'b0;
        end else begin
            if (ready_out && valid_in) begin
                // 捕获新数据
                data_reg <= data;
                result_valid <= 1'b1;
            end else if (ready_in && result_valid) begin
                // 数据被接收，清除valid
                result_valid <= 1'b0;
            end
            
            // 当有新数据输入时，更新结果寄存器
            if (ready_out && valid_in) begin
                result_reg <= internal_result;
            end
        end
    end

    // 实例化第一级子模块 - 处理低4位
    BitGroupAND #(
        .WIDTH(4)
    ) low_bits_and (
        .bit_group(data_reg[3:0]),
        .group_result(stage1_result_low)
    );

    // 实例化第一级子模块 - 处理高4位
    BitGroupAND #(
        .WIDTH(4)
    ) high_bits_and (
        .bit_group(data_reg[7:4]),
        .group_result(stage1_result_high)
    );

    // 实例化最终级子模块 - 合并结果
    FinalStageAND final_and (
        .partial_result_1(stage1_result_low),
        .partial_result_2(stage1_result_high),
        .final_result(internal_result)
    );
    
    // 输出结果
    assign result = result_reg;

endmodule

// 第一级子模块 - 对一组位进行与运算
module BitGroupAND #(
    parameter WIDTH = 4
) (
    input  wire [WIDTH-1:0] bit_group,
    output wire             group_result
);
    assign group_result = &bit_group;
endmodule

// 最终级子模块 - 合并两个部分结果
module FinalStageAND (
    input  wire partial_result_1,
    input  wire partial_result_2,
    output wire final_result
);
    assign final_result = partial_result_1 & partial_result_2;
endmodule

`default_nettype wire