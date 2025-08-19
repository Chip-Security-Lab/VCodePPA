module SyncNOT(
    input clk,
    input [15:0] async_in,
    output reg [15:0] synced_not
);
    always @(posedge clk) begin
        synced_not <= ~async_in;  // 时钟同步取反
    end
endmodule
