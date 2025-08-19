//SystemVerilog
// Top level module
module dram_cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input src_clk,
    input dst_clk, 
    input async_cmd,
    output reg sync_cmd
);

    // Internal signals
    wire sync_chain_out;
    
    // Instantiate sync chain module
    sync_chain #(
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_chain_inst (
        .dst_clk(dst_clk),
        .async_cmd(async_cmd),
        .sync_chain_out(sync_chain_out)
    );

    // Instantiate edge detector module
    edge_detector edge_detector_inst (
        .dst_clk(dst_clk),
        .sync_chain_out(sync_chain_out),
        .sync_cmd(sync_cmd)
    );

endmodule

// Synchronization chain submodule
module sync_chain #(
    parameter SYNC_STAGES = 2
)(
    input dst_clk,
    input async_cmd,
    output reg sync_chain_out
);

    reg [SYNC_STAGES-1:0] sync_chain;

    always @(posedge dst_clk) begin
        sync_chain <= {sync_chain[SYNC_STAGES-2:0], async_cmd};
        sync_chain_out <= sync_chain[SYNC_STAGES-1];
    end

endmodule

// Edge detector submodule
module edge_detector (
    input dst_clk,
    input sync_chain_out,
    output reg sync_cmd
);

    always @(posedge dst_clk) begin
        sync_cmd <= sync_cmd ^ (sync_chain_out & ~sync_cmd);
    end

endmodule