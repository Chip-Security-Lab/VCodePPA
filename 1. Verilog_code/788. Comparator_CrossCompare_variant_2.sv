//SystemVerilog
module Comparator_CrossCompare #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] a0,b0,a1,b1, // 两组输入对
    output             eq0,eq1,     // 独立比较结果
    output             all_eq       // 全等信号
);
    wire [WIDTH-1:0] diff0, diff1;
    wire zero0, zero1;
    
    // 使用二进制补码减法算法实现比较
    assign diff0 = a0 + (~b0) + 1'b1; // a0 - b0 = a0 + 取反(b0) + 1
    assign diff1 = a1 + (~b1) + 1'b1; // a1 - b1 = a1 + 取反(b1) + 1
    
    // 判断差值是否为零
    assign zero0 = (diff0 == {WIDTH{1'b0}});
    assign zero1 = (diff1 == {WIDTH{1'b0}});
    
    // 输出信号赋值
    assign eq0 = zero0;
    assign eq1 = zero1;
    assign all_eq = eq0 & eq1;
endmodule