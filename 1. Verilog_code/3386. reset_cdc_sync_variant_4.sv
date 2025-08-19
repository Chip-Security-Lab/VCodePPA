//SystemVerilog
//-----------------------------------------------------------------------------
// Module: reset_cdc_sync
// Description: Reset Clock Domain Crossing Synchronizer with improved structure
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module reset_cdc_sync (
    input  wire dst_clk,       // Destination clock
    input  wire async_rst_in,  // Asynchronous reset input
    output wire synced_rst     // Synchronized reset output
);

    // Reset synchronization pipeline registers
    reg rst_meta_stage;       // Metastability capture stage
    reg rst_sync_stage;       // Synchronized output stage

    // Two-stage synchronizer with conditional operator implementation
    always @(posedge dst_clk or posedge async_rst_in) begin
        rst_meta_stage <= async_rst_in ? 1'b1 : 1'b0;
        rst_sync_stage <= async_rst_in ? 1'b1 : rst_meta_stage;
    end

    // Clean output assignment
    assign synced_rst = rst_sync_stage;

endmodule