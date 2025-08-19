//SystemVerilog
// Top-level module: Hierarchically structured reset stretch and synchronizer
module reset_stretch_sync #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    output wire sync_rst_n
);

    // Internal signals for submodule interconnection
    wire meta_sync;
    wire stretch_reset_n;

    // -----------------------------------------------------------
    // Reset Synchronizer: Double-flop async reset to clock domain
    // -----------------------------------------------------------
    reset_synchronizer u_reset_synchronizer (
        .clk        (clk),
        .async_rst_n(async_rst_n),
        .meta_sync  (meta_sync)
    );

    // -----------------------------------------------------------
    // Reset Stretch Logic: Hold reset active for STRETCH_COUNT cycles
    // -----------------------------------------------------------
    reset_stretch #(
        .STRETCH_COUNT(STRETCH_COUNT)
    ) u_reset_stretch (
        .clk           (clk),
        .sync_in       (meta_sync),
        .async_rst_n   (async_rst_n),
        .stretched_rst_n(stretch_reset_n)
    );

    // -----------------------------------------------------------
    // Output register for sync_rst_n (final stage)
    // -----------------------------------------------------------
    sync_rst_out u_sync_rst_out (
        .clk            (clk),
        .stretched_rst_n(stretch_reset_n),
        .meta_sync      (meta_sync),
        .sync_rst_n     (sync_rst_n)
    );

endmodule

// -------------------------------------------------------------------------
// Submodule: reset_synchronizer
// Double-flop synchronizer for asynchronous reset input
// -------------------------------------------------------------------------
module reset_synchronizer (
    input  wire clk,
    input  wire async_rst_n,
    output reg  meta_sync
);
    // Two-stage synchronizer
    reg meta_ff;

    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_ff   <= 1'b0;
            meta_sync <= 1'b0;
        end else begin
            meta_ff   <= 1'b1;
            meta_sync <= meta_ff;
        end
    end
endmodule

// -------------------------------------------------------------------------
// Submodule: reset_stretch
// Stretches the reset for STRETCH_COUNT clock cycles after async reset deassertion
// -------------------------------------------------------------------------
module reset_stretch #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire sync_in,
    input  wire async_rst_n,
    output reg  stretched_rst_n
);
    reg [$clog2(STRETCH_COUNT):0] stretch_counter;
    reg reset_detected;

    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            reset_detected   <= 1'b1;
            stretch_counter  <= 0;
            stretched_rst_n  <= 1'b0;
        end else begin
            if (reset_detected) begin
                if (stretch_counter < STRETCH_COUNT - 1) begin
                    stretch_counter <= stretch_counter + 1;
                    stretched_rst_n <= 1'b0;
                end else begin
                    reset_detected  <= 1'b0;
                    stretched_rst_n <= 1'b1;
                end
            end else begin
                stretched_rst_n <= sync_in;
            end
        end
    end
endmodule

// -------------------------------------------------------------------------
// Submodule: sync_rst_out
// Output register for the final synchronized reset signal
// -------------------------------------------------------------------------
module sync_rst_out (
    input  wire clk,
    input  wire stretched_rst_n,
    input  wire meta_sync,
    output reg  sync_rst_n
);
    always @(posedge clk) begin
        if (!stretched_rst_n)
            sync_rst_n <= 1'b0;
        else
            sync_rst_n <= meta_sync;
    end
endmodule