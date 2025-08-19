module decoder_hybrid_rst #(parameter SYNC_RST=1) (
    input clk, async_rst, sync_rst,
    input [3:0] addr,
    output reg [15:0] decoded
);
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) decoded <= 0;
        else if (SYNC_RST && sync_rst) decoded <= 0;
        else decoded <= 1'b1 << addr;
    end
endmodule