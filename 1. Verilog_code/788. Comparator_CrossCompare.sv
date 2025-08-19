module Comparator_CrossCompare #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] a0,b0,a1,b1, // 两组输入对
    output             eq0,eq1,     // 独立比较结果
    output             all_eq       // 全等信号
);
    assign eq0 = (a0 == b0);
    assign eq1 = (a1 == b1);
    assign all_eq = eq0 & eq1;
endmodule