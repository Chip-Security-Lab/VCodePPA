//SystemVerilog
// Top-level module
module config_polarity_rst_sync (
    input  wire clk,
    input  wire reset_in,
    input  wire active_high,
    output wire sync_reset
);
    wire normalized_reset;
    wire sync_reset_int;
    
    // Early polarity conversion - moved combinational logic before registers
    wire reset_normalized = active_high ? reset_in : !reset_in;
    
    // Modified synchronizer with early normalization
    reset_synchronizer u_synchronizer (
        .clk            (clk),
        .async_reset    (reset_normalized),
        .sync_reset     (sync_reset_int)
    );
    
    // Final output polarity adjustment
    assign sync_reset = active_high ? sync_reset_int : !sync_reset_int;
    
endmodule

// Submodule for reset synchronization chain
module reset_synchronizer (
    input  wire clk,
    input  wire async_reset,
    output wire sync_reset
);
    // Two-stage synchronizer to prevent metastability
    reg [1:0] sync_chain;
    
    always @(posedge clk) begin
        sync_chain <= {sync_chain[0], async_reset};
    end
    
    assign sync_reset = sync_chain[1];
endmodule