//SystemVerilog
module config_polarity_rst_sync (
    input  wire clk,
    input  wire reset_in,
    input  wire active_high,
    output wire sync_reset
);
    // Internal signals for synchronization
    reg  normalized_reset;
    reg  sync_ff1, sync_ff2;
    reg  config_active_high;
    reg  valid;
    
    // Reset normalization and configuration capture
    always @(posedge clk) begin
        normalized_reset <= active_high ? reset_in : ~reset_in;
        config_active_high <= active_high;
        valid <= 1'b1;
    end
    
    // Two-stage synchronizer
    always @(posedge clk) begin
        sync_ff1 <= normalized_reset;
        sync_ff2 <= sync_ff1;
    end
    
    // Output generation using optimized logic
    assign sync_reset = valid ? (config_active_high ? sync_ff2 : ~sync_ff2) : 1'b0;
endmodule