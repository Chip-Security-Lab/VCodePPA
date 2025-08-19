//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: basic_reset_sync
// Description: Synchronous reset synchronizer with hierarchical structure
//-----------------------------------------------------------------------------
module basic_reset_sync (
    input  wire clk,
    input  wire async_reset_n,
    output wire sync_reset_n
);

    wire meta_flop_out;

    // Instantiate the meta-flop synchronizer stage
    meta_flop_stage u_meta_flop_stage (
        .clk            (clk),
        .async_reset_n  (async_reset_n),
        .meta_flop_out  (meta_flop_out)
    );

    // Instantiate the reset output register stage
    sync_reset_stage u_sync_reset_stage (
        .clk            (clk),
        .async_reset_n  (async_reset_n),
        .meta_flop_in   (meta_flop_out),
        .sync_reset_n   (sync_reset_n)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: meta_flop_stage
// Function: First synchronizing stage for asynchronous reset
//-----------------------------------------------------------------------------
module meta_flop_stage (
    input  wire clk,
    input  wire async_reset_n,
    output reg  meta_flop_out
);
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            meta_flop_out <= 1'b0;
        else
            meta_flop_out <= 1'b1;
    end
endmodule

//-----------------------------------------------------------------------------
// Submodule: sync_reset_stage
// Function: Second synchronizing stage to generate synchronous reset output
//-----------------------------------------------------------------------------
module sync_reset_stage (
    input  wire clk,
    input  wire async_reset_n,
    input  wire meta_flop_in,
    output reg  sync_reset_n
);
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            sync_reset_n <= 1'b0;
        else
            sync_reset_n <= meta_flop_in;
    end
endmodule