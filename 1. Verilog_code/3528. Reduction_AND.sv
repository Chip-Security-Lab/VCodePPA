module Reduction_AND(
    input [7:0] data,
    output result
);
    assign result = &data; // 8位缩位与运算
endmodule
