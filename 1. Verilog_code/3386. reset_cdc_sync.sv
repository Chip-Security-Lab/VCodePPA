module reset_cdc_sync(
    input wire dst_clk,
    input wire async_rst_in,
    output reg synced_rst
);
    reg meta_flop;
    always @(posedge dst_clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            meta_flop <= 1'b1;
            synced_rst <= 1'b1;
        end else begin
            meta_flop <= 1'b0;
            synced_rst <= meta_flop;
        end
    end
endmodule