module HybridNOT(
    input [7:0] byte_in,
    output [7:0] byte_out
);
    assign byte_out = byte_in ^ 8'hFF;  // 异或实现取反
endmodule
