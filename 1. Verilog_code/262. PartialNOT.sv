module PartialNOT(
    input [15:0] word,
    output [15:0] modified
);
    assign modified[15:8] = word[15:8];  // 高字节保持
    assign modified[7:0] = ~word[7:0];   // 低字节取反
endmodule
