module ITRC_ClockCrossing #(
    parameter SYNC_STAGES = 2
)(
    input src_clk,
    input dst_clk,
    input async_int,
    output sync_int
);
    reg [SYNC_STAGES-1:0] sync_chain;
    
    always @(posedge dst_clk) begin
        sync_chain <= {sync_chain[SYNC_STAGES-2:0], async_int};
    end
    
    assign sync_int = sync_chain[SYNC_STAGES-1];
endmodule