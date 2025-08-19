//SystemVerilog
//===================================================================
//===================================================================
// Module: cdc_clock_gate
// Description: Clock domain crossing with structured pipeline for 
//              safe clock gating implementation
//===================================================================
module cdc_clock_gate (
    input  wire src_clk,    // Source clock domain
    input  wire dst_clk,    // Destination clock domain
    input  wire src_en,     // Enable signal (source domain)
    input  wire rst_n,      // Active-low reset
    output wire gated_dst_clk // Gated clock output
);
    // CDC synchronization pipeline
    wire src_en_buffered;   // Buffered source enable
    reg  cdc_meta;          // Metastability prevention stage
    reg  cdc_sync;          // Synchronization stage
    wire sync_en;           // Synchronized enable signal

    // Buffered source enable - pushing register forward through source path
    assign src_en_buffered = src_en;

    // Destination domain synchronization pipeline with moved register
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            cdc_meta <= 1'b0;
            cdc_sync <= 1'b0;
        end else begin
            cdc_meta <= src_en_buffered; // Direct capture from buffered input
            cdc_sync <= cdc_meta;        // Second stage synchronization
        end
    end

    // Final synchronization signal
    assign sync_en = cdc_sync;
    
    // Clock gating control
    assign gated_dst_clk = dst_clk & sync_en;

endmodule