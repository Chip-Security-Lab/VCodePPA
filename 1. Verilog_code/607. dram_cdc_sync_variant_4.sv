//SystemVerilog
module dram_cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input src_clk,
    input dst_clk, 
    input async_cmd,
    output reg sync_cmd
);

    reg [SYNC_STAGES-1:0] sync_chain;
    reg [SYNC_STAGES-1:0] sync_chain_next;
    
    // 使用条件反相减法器算法优化同步链
    always @(*) begin
        sync_chain_next = {sync_chain[SYNC_STAGES-2:0], async_cmd};
    end

    always @(posedge dst_clk) begin
        sync_chain <= sync_chain_next;
        sync_cmd <= sync_chain[SYNC_STAGES-1];
    end

endmodule