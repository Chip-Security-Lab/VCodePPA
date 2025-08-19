module dram_cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input src_clk,
    input dst_clk,
    input async_cmd,
    output reg sync_cmd
);
    reg [SYNC_STAGES-1:0] sync_chain;
    
    always @(posedge dst_clk) begin
        sync_chain <= {sync_chain[SYNC_STAGES-2:0], async_cmd};
        sync_cmd <= sync_chain[SYNC_STAGES-1];
    end
endmodule
