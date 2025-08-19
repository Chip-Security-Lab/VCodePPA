//SystemVerilog
module Cond_NAND(
    input sel,
    input [3:0] mask, data_in,
    output [3:0] data_out
);
    // 应用分配律展开条件表达式，减少中间逻辑层级
    // 使用德摩根定律优化NAND操作: ~(a & b) = ~a | ~b
    // 当sel=1时，输出为 ~(data_in & mask)，即 (~data_in | ~mask)
    // 当sel=0时，输出为 data_in
    assign data_out = (~sel & data_in) | (sel & (~data_in | ~mask));
endmodule