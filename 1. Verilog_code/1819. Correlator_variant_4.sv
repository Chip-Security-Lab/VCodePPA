//SystemVerilog
module Correlator #(parameter W=8) (
    input clk,
    input [W-1:0] sample,
    output reg [W+3:0] corr_out
);
    parameter [3:0] TAP0 = 4'hA;
    parameter [3:0] TAP1 = 4'h3;
    parameter [3:0] TAP2 = 4'h5;
    parameter [3:0] TAP3 = 4'h7;
    
    reg [W-1:0] shift_reg [0:3];
    reg [W+3:0] corr_reg;
    integer i;
    
    always @(posedge clk) begin
        // 移位寄存器
        for(i=3; i>0; i=i-1)
            shift_reg[i] <= shift_reg[i-1];
        shift_reg[0] <= sample;
        
        // 预计算部分和
        corr_reg <= (shift_reg[3] * TAP3) + 
                   (shift_reg[2] * TAP2) +
                   (shift_reg[1] * TAP1) + 
                   (shift_reg[0] * TAP0);
                   
        // 输出寄存器
        corr_out <= corr_reg;
    end
endmodule