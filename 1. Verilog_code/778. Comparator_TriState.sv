module Comparator_TriState #(parameter WIDTH = 12) (
    input              en,        // 输出使能
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output tri         equal
);
    wire cmp_result = (src1 == src2);
    assign equal = en ? cmp_result : 1'bz;
endmodule