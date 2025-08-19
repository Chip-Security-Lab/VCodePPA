//SystemVerilog
module ITRC_ClockCrossing #(
    parameter SYNC_STAGES = 2
)(
    input src_clk,
    input dst_clk,
    input async_int,
    output sync_int
);
    reg [SYNC_STAGES-1:0] sync_chain;
    reg [SYNC_STAGES-1:0] sync_chain_nxt;
    
    always @(posedge dst_clk) begin
        sync_chain <= sync_chain_nxt;
    end
    
    always @(*) begin
        sync_chain_nxt = {sync_chain[SYNC_STAGES-2:0], async_int};
    end
    
    assign sync_int = sync_chain[SYNC_STAGES-1];
endmodule