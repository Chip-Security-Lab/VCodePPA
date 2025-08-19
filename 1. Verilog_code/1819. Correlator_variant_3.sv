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
    
    reg [W-1:0] shift_reg [0:3];
    reg [W+1:0] mult_res [0:3];
    wire [W+3:0] corr_sum;
    integer i;
    
    assign corr_sum = mult_res[0] + mult_res[1] + mult_res[2] + mult_res[3];
    
    always @(posedge clk) begin
        // 手动移位寄存器
        i = 3;
        while(i > 0) begin
            shift_reg[i] <= shift_reg[i-1];
            i = i - 1;
        end
        shift_reg[0] <= sample;
        
        // 预先计算每个乘法结果并寄存
        mult_res[0] <= shift_reg[0] * TAP0;
        mult_res[1] <= shift_reg[1] * TAP1;
        mult_res[2] <= shift_reg[2] * TAP2;
        mult_res[3] <= shift_reg[3] * TAP3;
        
        // 最后一级寄存最终结果
        corr_out <= corr_sum;
    end
endmodule