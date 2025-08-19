module async_fifo_sync #(parameter ADDR_W=4) (
    input wr_clk, rd_clk, rst,
    output reg [ADDR_W:0] synced_wptr
);
    wire [ADDR_W:0] gray_wptr;
    always @(posedge rd_clk) begin
        if(rst) synced_wptr <= 0;
        else synced_wptr <= {synced_wptr[ADDR_W-1:0], gray_wptr};
    end
endmodule