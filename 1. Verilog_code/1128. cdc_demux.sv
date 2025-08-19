module cdc_demux (
    input wire src_clk,                  // Source clock domain
    input wire dst_clk,                  // Destination clock domain
    input wire data_in,                  // Input data
    input wire [1:0] sel,                // Selection control
    output reg [3:0] sync_out            // Synchronized outputs
);
    reg [3:0] src_demux;                 // Source domain demux outputs
    reg [3:0] meta_stage;                // Metastability reduction registers
    
    // Source domain demultiplexing
    always @(posedge src_clk) begin
        src_demux <= 4'b0;
        src_demux[sel] <= data_in;
    end
    
    // Clock domain crossing with 2-stage synchronization
    always @(posedge dst_clk) begin
        meta_stage <= src_demux;         // First stage
        sync_out <= meta_stage;          // Second stage
    end
endmodule