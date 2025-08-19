module Reduction_NAND(
    input [7:0] vec,
    output result
);
    assign result = ~(&vec);  // 8输入转换
endmodule
