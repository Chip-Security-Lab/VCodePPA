module BusMask_NAND(
    input [31:0] data,
    input [31:0] mask,
    output [31:0] res
);
    assign res = ~(data & mask);  // 整型掩码
endmodule
