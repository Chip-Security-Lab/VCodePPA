//SystemVerilog
module Correlator #(parameter W=8) (
    input clk,
    input rst_n,
    input [W-1:0] sample,
    input valid_in,
    output reg valid_out,
    output reg [W+3:0] corr_out
);
    parameter [3:0] TAP0 = 4'hA;
    parameter [3:0] TAP1 = 4'h3;
    parameter [3:0] TAP2 = 4'h5;
    parameter [3:0] TAP3 = 4'h7;
    
    reg [W-1:0] shift_reg [0:3];
    reg [W+3:0] prod_stage1 [0:3];
    reg [W+3:0] sum_stage2_0;
    reg [W+3:0] sum_stage2_1;
    reg valid_stage1;
    reg valid_stage2;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0; i<4; i=i+1) begin
                shift_reg[i] <= 0;
                prod_stage1[i] <= 0;
            end
            {sum_stage2_0, sum_stage2_1, corr_out} <= 0;
            {valid_stage1, valid_stage2, valid_out} <= 0;
        end else begin
            // 移位寄存器更新
            for(i=3; i>0; i=i-1)
                shift_reg[i] <= shift_reg[i-1];
            shift_reg[0] <= sample;
            
            // 流水线控制信号
            valid_stage1 <= valid_in;
            valid_stage2 <= valid_stage1;
            valid_out <= valid_stage2;
            
            // 乘法运算
            prod_stage1[0] <= shift_reg[0] * TAP0;
            prod_stage1[1] <= shift_reg[1] * TAP1;
            prod_stage1[2] <= shift_reg[2] * TAP2;
            prod_stage1[3] <= shift_reg[3] * TAP3;
            
            // 加法运算
            sum_stage2_0 <= prod_stage1[0] + prod_stage1[1];
            sum_stage2_1 <= prod_stage1[2] + prod_stage1[3];
            corr_out <= sum_stage2_0 + sum_stage2_1;
        end
    end
endmodule