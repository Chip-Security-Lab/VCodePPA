//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005
module usb_bit_stuffer(
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    input  wire valid_i,
    output wire bit_o,
    output wire valid_o,
    output wire stuffed_o
);
    // 参数定义
    localparam MAX_ONES = 6;
    
    // 寄存器信号声明
    reg [2:0] ones_count_r;       // 已检测到的连续1的计数
    reg       input_bit_r;        // 寄存输入位以减少路径延迟
    reg       input_valid_r;      // 寄存输入有效信号
    reg [2:0] next_count_r;       // 下一个计数值
    reg       need_stuff_bit_r;   // 指示需要插入位
    reg       stuff_active_r;     // 插入位激活状态
    reg       bit_r;              // 输出位寄存器
    reg       valid_r;            // 输出有效寄存器
    reg       stuffed_r;          // 输出位填充指示寄存器
    
    // 组合逻辑信号
    wire      is_one_w;           // 当前位是否为1
    wire      is_zero_w;          // 当前位是否为0
    wire      max_ones_reached_w; // 是否达到最大连续1计数
    wire [2:0] next_count_w;      // 组合逻辑计算的下一个计数值
    wire      need_stuff_bit_w;   // 组合逻辑计算的插入位需求
    wire      bit_out_w;          // 组合逻辑计算的输出位
    wire      valid_out_w;        // 组合逻辑计算的有效输出
    wire      stuffed_out_w;      // 组合逻辑计算的填充指示

    // 输出赋值
    assign bit_o = bit_r;
    assign valid_o = valid_r;
    assign stuffed_o = stuffed_r;
    
    // =========== 组合逻辑部分 ===========
    
    // 位状态检测组合逻辑
    assign is_one_w = input_bit_r;
    assign is_zero_w = ~input_bit_r;
    assign max_ones_reached_w = (ones_count_r == MAX_ONES-1) && is_one_w;
    
    // 计数器组合逻辑
    assign next_count_w = (is_zero_w || max_ones_reached_w) ? 3'd0 :
                          (is_one_w) ? ones_count_r + 1'b1 : 
                          ones_count_r;
    
    // 插入位检测组合逻辑
    assign need_stuff_bit_w = max_ones_reached_w && input_valid_r;
    
    // 输出生成组合逻辑
    assign bit_out_w = (need_stuff_bit_r) ? 1'b0 : input_bit_r;
    assign valid_out_w = (need_stuff_bit_r || input_valid_r) ? 1'b1 : 1'b0;
    assign stuffed_out_w = need_stuff_bit_r;
    
    // =========== 时序逻辑部分 ===========
    
    // 阶段1: 输入捕获 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            input_bit_r <= 1'b0;
            input_valid_r <= 1'b0;
        end else begin
            input_bit_r <= bit_i;
            input_valid_r <= valid_i;
        end
    end
    
    // 计数器寄存更新 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            ones_count_r <= 3'd0;
        end else if (input_valid_r) begin
            ones_count_r <= next_count_w;
        end
    end
    
    // 插入位控制 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            need_stuff_bit_r <= 1'b0;
            stuff_active_r <= 1'b0;
        end else if (input_valid_r) begin
            need_stuff_bit_r <= need_stuff_bit_w;
            stuff_active_r <= need_stuff_bit_r;
        end else begin
            need_stuff_bit_r <= 1'b0;
            stuff_active_r <= 1'b0;
        end
    end
    
    // 输出寄存器 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_r <= 1'b0;
            valid_r <= 1'b0;
            stuffed_r <= 1'b0;
        end else begin
            bit_r <= bit_out_w;
            valid_r <= valid_out_w;
            stuffed_r <= stuffed_out_w;
        end
    end
    
endmodule