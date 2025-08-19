module BlockCompress #(BLK=4) (
    input clk, blk_en,
    input [BLK*8-1:0] data,
    output reg [15:0] code
);
always @(posedge clk) if(blk_en) 
    code <= ^data;  // 块异或压缩
endmodule
