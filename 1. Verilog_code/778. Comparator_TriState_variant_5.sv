//SystemVerilog
module Comparator_TriState #(parameter WIDTH = 8) (
    input              en,        // 输出使能
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output tri         equal
);
    // 直接比较两个输入是否相等
    wire cmp_result = (src1 == src2);
    
    // 三态输出控制
    assign equal = en ? cmp_result : 1'bz;
endmodule