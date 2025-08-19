//SystemVerilog
module cdc_demux (
    input wire src_clk,                  // Source clock domain
    input wire dst_clk,                  // Destination clock domain
    input wire data_in,                  // Input data
    input wire [1:0] sel,                // Selection control
    output reg [3:0] sync_out            // Synchronized outputs
);
    // Source domain registers - break down demux operation
    reg data_in_stage1;                  // Pipeline stage 1 for input data
    reg [1:0] sel_stage1;                // Pipeline stage 1 for selection
    reg [3:0] src_demux_stage1;          // Intermediate demux stage
    reg [3:0] src_demux_stage2;          // Final source domain stage
    
    // Destination domain synchronization registers
    reg [3:0] meta_stage1;               // First synchronization stage
    reg [3:0] meta_stage2;               // Second synchronization stage
    reg [3:0] meta_stage3;               // Third synchronization stage

    // Register input data
    always @(posedge src_clk) begin
        data_in_stage1 <= data_in;
    end
    
    // Register selection control
    always @(posedge src_clk) begin
        sel_stage1 <= sel;
    end
    
    // Prepare demux values - channel 0
    always @(posedge src_clk) begin
        src_demux_stage1[0] <= (sel_stage1 == 2'b00) ? data_in_stage1 : 1'b0;
    end
    
    // Prepare demux values - channel 1
    always @(posedge src_clk) begin
        src_demux_stage1[1] <= (sel_stage1 == 2'b01) ? data_in_stage1 : 1'b0;
    end
    
    // Prepare demux values - channel 2
    always @(posedge src_clk) begin
        src_demux_stage1[2] <= (sel_stage1 == 2'b10) ? data_in_stage1 : 1'b0;
    end
    
    // Prepare demux values - channel 3
    always @(posedge src_clk) begin
        src_demux_stage1[3] <= (sel_stage1 == 2'b11) ? data_in_stage1 : 1'b0;
    end
    
    // Pipeline stage 3 - final source domain stage
    always @(posedge src_clk) begin
        src_demux_stage2 <= src_demux_stage1;
    end
    
    // CDC first stage synchronization
    always @(posedge dst_clk) begin
        meta_stage1 <= src_demux_stage2;
    end
    
    // CDC second stage synchronization
    always @(posedge dst_clk) begin
        meta_stage2 <= meta_stage1;
    end
    
    // CDC third stage synchronization
    always @(posedge dst_clk) begin
        meta_stage3 <= meta_stage2;
    end
    
    // Output stage
    always @(posedge dst_clk) begin
        sync_out <= meta_stage3;
    end
endmodule