// 异步组合逻辑比较器，带参数化位宽
module Comparator_BaseAsync #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_a,    // 输入数据A
    input  [WIDTH-1:0] data_b,    // 输入数据B
    output reg         o_equal    // 等于比较结果
);                             
    always @(*) begin             // 纯组合逻辑
        o_equal = (data_a == data_b);
    end
endmodule
