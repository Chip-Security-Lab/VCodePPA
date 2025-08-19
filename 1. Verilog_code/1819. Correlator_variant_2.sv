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
    
    reg [W-1:0] sample_reg;
    reg [W-1:0] shift_reg [0:2];
    
    // 部分乘积寄存器
    reg [W+3:0] prod0, prod1, prod2, prod3;
    
    always @(posedge clk) begin
        // 输入寄存化
        sample_reg <= sample;
        
        // 手动移位寄存器
        shift_reg[0] <= sample_reg;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        
        // 提前计算各个乘积并寄存
        prod0 <= sample_reg * TAP0;
        prod1 <= shift_reg[0] * TAP1;
        prod2 <= shift_reg[1] * TAP2;
        prod3 <= shift_reg[2] * TAP3;
        
        // 最终加法操作
        corr_out <= prod0 + prod1 + prod2 + prod3;
    end
endmodule