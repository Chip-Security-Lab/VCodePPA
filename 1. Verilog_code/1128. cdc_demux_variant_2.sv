//SystemVerilog
module cdc_demux (
    input wire src_clk,                  // Source clock domain
    input wire dst_clk,                  // Destination clock domain
    input wire data_in,                  // Input data
    input wire [1:0] sel,                // Selection control
    output reg [3:0] sync_out            // Synchronized outputs
);
    // Source domain pipeline registers
    reg data_in_stage1;                  // First pipeline stage for data_in
    reg data_in_stage2;                  // Second pipeline stage for data_in
    reg [1:0] sel_stage1;                // First pipeline stage for sel
    reg [1:0] sel_stage2;                // Second pipeline stage for sel
    
    // Source domain demux pipeline
    reg [3:0] src_demux_stage1;          // First stage demux result
    reg [3:0] src_demux_stage2;          // Second stage demux result
    
    // CDC synchronization pipeline
    reg [3:0] meta_stage1;               // First metastability reduction stage
    reg [3:0] meta_stage2;               // Second metastability reduction stage
    reg [3:0] meta_stage3;               // Third metastability reduction stage
    
    // Input registration - first pipeline stage
    always @(posedge src_clk) begin
        data_in_stage1 <= data_in;
        sel_stage1 <= sel;
    end
    
    // Second pipeline stage - registered inputs
    always @(posedge src_clk) begin
        data_in_stage2 <= data_in_stage1;
        sel_stage2 <= sel_stage1;
    end
    
    // Demux operation - first stage (decode selection)
    always @(posedge src_clk) begin
        src_demux_stage1 <= 4'b0;
        case(sel_stage2)
            2'b00: src_demux_stage1[0] <= data_in_stage2;
            2'b01: src_demux_stage1[1] <= data_in_stage2;
            2'b10: src_demux_stage1[2] <= data_in_stage2;
            2'b11: src_demux_stage1[3] <= data_in_stage2;
        endcase
    end
    
    // Demux operation - second stage (stabilize demux output)
    always @(posedge src_clk) begin
        src_demux_stage2 <= src_demux_stage1;
    end
    
    // Clock domain crossing with 3-stage synchronization for better MTBF
    always @(posedge dst_clk) begin
        meta_stage1 <= src_demux_stage2;   // First CDC stage
        meta_stage2 <= meta_stage1;        // Second CDC stage
        meta_stage3 <= meta_stage2;        // Third CDC stage
        sync_out <= meta_stage3;           // Final output stage
    end
endmodule