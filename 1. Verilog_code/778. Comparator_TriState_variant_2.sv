//SystemVerilog
module Comparator_TriState #(parameter WIDTH = 12) (
    input              en,        // 输出使能
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output reg         equal
);
    wire [WIDTH-1:0] diff;        // 差值
    wire cmp_result;
    
    // 使用二进制补码减法实现
    assign diff = src1 + (~src2 + 1'b1);  // src1 - src2 补码实现
    assign cmp_result = (diff == {WIDTH{1'b0}});  // 如果差值为0，则相等
    
    always @(*) begin
        if (en)
            equal = cmp_result;
        else
            equal = 1'bz;
    end
endmodule