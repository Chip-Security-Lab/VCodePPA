module DistributedOR(
    input [3:0] bits,
    output result
);
    assign result = |bits;  // 4输入缩位或
endmodule
