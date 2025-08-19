//SystemVerilog
module cdc_demux (
    input wire src_clk,                  // Source clock domain
    input wire dst_clk,                  // Destination clock domain
    input wire data_in,                  // Input data
    input wire [1:0] sel,                // Selection control
    output reg [3:0] sync_out            // Synchronized outputs
);
    // Register input data in source domain
    reg data_in_reg;
    
    // First stage: register input data
    always @(posedge src_clk) begin
        data_in_reg <= data_in;
    end
    
    // Selection signals directly to destination domain
    // Moving demux operation to destination domain
    reg [1:0] sel_meta, sel_sync;
    
    // Synchronize selection signals to destination domain
    always @(posedge dst_clk) begin
        sel_meta <= sel;
        sel_sync <= sel_meta;
    end
    
    // Data synchronization registers
    reg data_meta, data_sync;
    
    // Synchronize data to destination domain
    always @(posedge dst_clk) begin
        data_meta <= data_in_reg;
        data_sync <= data_meta;
    end
    
    // Perform demultiplexing in destination domain
    // This moves the combinational logic after the CDC
    always @(posedge dst_clk) begin
        sync_out <= 4'b0;
        sync_out[sel_sync] <= data_sync;
    end
endmodule