//SystemVerilog
module Comparator_CrossCompare #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] a0,b0,a1,b1, // 两组输入对
    output             eq0,eq1,     // 独立比较结果
    output             all_eq       // 全等信号
);
    // 使用查找表辅助减法器实现等值比较
    wire [7:0] diff0_low, diff0_high;
    wire [7:0] diff1_low, diff1_high;
    
    // 查找表ROM - 实现减法辅助表
    reg [7:0] sub_lut [0:255];
    
    // 初始化查找表
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i;
        end
    end
    
    // 分段计算差值
    wire [7:0] a0_low = a0[7:0];
    wire [7:0] a0_high = a0[15:8];
    wire [7:0] b0_low = b0[7:0];
    wire [7:0] b0_high = b0[15:8];
    
    wire [7:0] a1_low = a1[7:0];
    wire [7:0] a1_high = a1[15:8];
    wire [7:0] b1_low = b1[7:0];
    wire [7:0] b1_high = b1[15:8];
    
    // 使用查找表实现减法比较
    wire [8:0] temp0_low, temp0_high;
    wire [8:0] temp1_low, temp1_high;
    
    // 查表减法实现
    assign temp0_low = {1'b0, sub_lut[a0_low]} - {1'b0, sub_lut[b0_low]};
    assign temp0_high = {1'b0, sub_lut[a0_high]} - {1'b0, sub_lut[b0_high]};
    assign temp1_low = {1'b0, sub_lut[a1_low]} - {1'b0, sub_lut[b1_low]};
    assign temp1_high = {1'b0, sub_lut[a1_high]} - {1'b0, sub_lut[b1_high]};
    
    // 差值为零表示相等
    assign diff0_low = temp0_low[7:0];
    assign diff0_high = temp0_high[7:0];
    assign diff1_low = temp1_low[7:0];
    assign diff1_high = temp1_high[7:0];
    
    // 分段结果合并判断相等
    wire eq0_low = (diff0_low == 8'b0);
    wire eq0_high = (diff0_high == 8'b0);
    wire eq1_low = (diff1_low == 8'b0);
    wire eq1_high = (diff1_high == 8'b0);
    
    // 输出信号生成
    assign eq0 = eq0_low & eq0_high;
    assign eq1 = eq1_low & eq1_high;
    assign all_eq = eq0 & eq1;
endmodule