//SystemVerilog
module Comparator_TriState #(parameter WIDTH = 12) (
    input              en,        // 输出使能
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output tri         equal
);
    wire [WIDTH-1:0] diff;
    wire zero_result;
    
    // 使用二进制补码减法代替直接比较
    // 当两个数相等时，差值为0
    assign diff = src1 + (~src2 + 1'b1); // 二进制补码减法: src1 - src2
    assign zero_result = (diff == {WIDTH{1'b0}}); // 检查差值是否为0
    
    // 三态输出逻辑
    assign equal = en ? zero_result : 1'bz;
    
endmodule