//SystemVerilog
//IEEE 1364-2005 SystemVerilog
`timescale 1ns / 1ps

module pl_reg_dualport #(parameter W=16) (
    input wire clk, 
    input wire wr1_en, 
    input wire wr2_en,
    input wire [W-1:0] wr1_data, 
    input wire [W-1:0] wr2_data,
    output reg [W-1:0] q
);
    // 阶段1: 数据路径分割 - 输入数据寄存捕获
    reg wr1_en_r, wr2_en_r;
    reg [W-1:0] wr1_data_r, wr2_data_r;
    
    always @(posedge clk) begin
        wr1_en_r <= wr1_en;
        wr2_en_r <= wr2_en;
        wr1_data_r <= wr1_data;
        wr2_data_r <= wr2_data;
    end
    
    // 阶段2: 数据处理路径 - 减法器和选择器实现
    // 减法运算模块 - 具有明确的数据流
    wire [7:0] minuend;
    wire [7:0] subtrahend;
    wire [7:0] subtrahend_comp;
    reg [W-1:0] sub_result_r;
    
    assign minuend = wr1_data_r[7:0];            // 被减数
    assign subtrahend = wr2_data_r[7:0];         // 减数
    assign subtrahend_comp = ~subtrahend + 1'b1; // 减数的补码
    
    // 阶段2: 计算减法结果并存储
    always @(posedge clk) begin
        sub_result_r[7:0] <= minuend + subtrahend_comp; // 补码加法实现减法
        sub_result_r[W-1:8] <= {(W-8){1'b0}};      // 高位填充0
    end
    
    // 阶段3: 数据选择路径
    reg [W-1:0] data_selected;
    reg [1:0] select_control_r;
    
    always @(posedge clk) begin
        select_control_r <= {wr1_en_r, wr2_en_r};
    end
    
    // 基于存储的控制信号选择输出数据
    always @(*) begin
        case(select_control_r)
            2'b10: data_selected = wr1_data_r;
            2'b01: data_selected = wr2_data_r;
            2'b11: data_selected = sub_result_r;     // 当两个写使能都有效时，使用减法结果
            default: data_selected = q;            // 保持当前值
        endcase
    end
    
    // 阶段4: 输出寄存器路径
    always @(posedge clk) begin
        q <= data_selected;
    end
endmodule