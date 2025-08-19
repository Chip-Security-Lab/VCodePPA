//SystemVerilog
// Top-level module: Hierarchical reset synchronizer
module basic_reset_sync (
    input  wire clk,
    input  wire async_reset_n,
    output wire sync_reset_n
);

    // Internal signals for inter-module connection
    wire meta_flop_out;

    // ---------------------------------------------------------
    // Meta-stability filter stage: First flip-flop synchronizer
    // ---------------------------------------------------------
    meta_flop_sync u_meta_flop_sync (
        .clk            (clk),
        .async_reset_n  (async_reset_n),
        .meta_flop_out  (meta_flop_out)
    );

    // ---------------------------------------------------------
    // Synchronous reset generator: Second flip-flop stage
    // ---------------------------------------------------------
    sync_reset_stage u_sync_reset_stage (
        .clk            (clk),
        .async_reset_n  (async_reset_n),
        .meta_flop_in   (meta_flop_out),
        .sync_reset_n   (sync_reset_n)
    );

endmodule

// ---------------------------------------------------------
// Module: meta_flop_sync
// Purpose: Synchronizes the asynchronous reset input using
//          the first stage flip-flop.
// ---------------------------------------------------------
module meta_flop_sync (
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

// ---------------------------------------------------------
// Module: sync_reset_stage
// Purpose: Generates the synchronized reset output using the
//          second stage flip-flop.
// ---------------------------------------------------------
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