module sync_2ff_en #(parameter DW=8) (
    input src_clk, dst_clk, rst_n, en,
    input [DW-1:0] async_in,
    output reg [DW-1:0] synced_out
);
    reg [DW-1:0] sync_ff;
    always @(posedge dst_clk or negedge rst_n) begin
        if(!rst_n) {synced_out, sync_ff} <= 0;
        else if(en) {synced_out, sync_ff} <= {sync_ff, async_in};
    end
endmodule