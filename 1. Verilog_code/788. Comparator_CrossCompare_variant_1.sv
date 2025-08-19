//SystemVerilog
module Comparator_CrossCompare #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] a0,b0,a1,b1, // 两组输入对
    output             eq0,eq1,     // 独立比较结果
    output             all_eq       // 全等信号
);
    wire [WIDTH-1:0] diff0, diff1;          // 差异向量
    wire             carry_out0, carry_out1; // 进位输出
    
    // 使用条件反相减法器算法实现比较
    // 计算 a0-b0，若结果为0则相等
    assign {carry_out0, diff0} = {1'b1, a0} + {1'b0, ~b0} + 1'b1;
    // 计算 a1-b1，若结果为0则相等
    assign {carry_out1, diff1} = {1'b1, a1} + {1'b0, ~b1} + 1'b1;
    
    // 判断差值是否为零来决定是否相等
    assign eq0 = (diff0 == {WIDTH{1'b0}});
    assign eq1 = (diff1 == {WIDTH{1'b0}});
    
    // 全等信号
    assign all_eq = eq0 & eq1;
endmodule