module Sync_NAND(
    input clk,
    input [7:0] d1, d2,
    output reg [7:0] q
);
    always @(posedge clk) begin
        q <= ~(d1 & d2);  // 时钟驱动输出
    end
endmodule
