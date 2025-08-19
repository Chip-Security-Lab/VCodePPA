//SystemVerilog
module Correlator #(parameter W=8) (
    input clk,
    input [W-1:0] sample,
    output reg [W+3:0] corr_out
);
    // 定义抽头系数
    parameter [3:0] TAP0 = 4'hA;
    parameter [3:0] TAP1 = 4'h3;
    parameter [3:0] TAP2 = 4'h5;
    parameter [3:0] TAP3 = 4'h7;
    
    // 样本延迟链 - 前移到乘法之后
    reg [W-1:0] sample_d1, sample_d2, sample_d3;
    
    // 直接在输入处计算乘法结果，移除乘法结果寄存
    wire [W+3:0] mult0 = sample * TAP0;
    wire [W+3:0] mult1 = sample * TAP1;
    wire [W+3:0] mult2 = sample * TAP2;
    wire [W+3:0] mult3 = sample * TAP3;
    
    // 存储延迟的乘法结果
    reg [W+3:0] mult1_d1;
    reg [W+3:0] mult2_d2;
    reg [W+3:0] mult3_d3;
    
    // 移位和乘法结果延迟
    always @(posedge clk) begin
        sample_d1 <= sample;
        sample_d2 <= sample_d1;
        sample_d3 <= sample_d2;
        
        mult1_d1 <= mult1;
        mult2_d2 <= mult2;
        mult3_d3 <= mult3;
    end
    
    // 相关性累加计算
    always @(posedge clk) begin
        corr_out <= mult0 + mult1_d1 + mult2_d2 + mult3_d3;
    end
    
endmodule