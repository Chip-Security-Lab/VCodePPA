//SystemVerilog
module cdc_demux (
    input wire src_clk,                  // Source clock domain
    input wire dst_clk,                  // Destination clock domain
    input wire rst_n,                    // Active low reset
    input wire data_valid,               // Input data valid signal
    input wire data_in,                  // Input data
    input wire [1:0] sel,                // Selection control
    output reg [3:0] sync_out,           // Synchronized outputs
    output reg sync_valid                // Output valid signal
);
    // Source domain pipeline registers
    reg data_in_stage1;
    reg [1:0] sel_stage1;
    reg valid_stage1;
    
    // Source domain demux pipeline registers
    reg [3:0] src_demux_stage1;
    reg [3:0] src_demux_stage2;
    reg valid_src_stage1;
    reg valid_src_stage2;
    
    // CDC synchronization registers
    reg [3:0] meta_stage1;
    reg valid_meta_stage1;
    reg [3:0] meta_stage2;
    reg valid_meta_stage2;
    
    // Source domain pipeline (src_clk domain) - 合并所有src_clk触发的always块
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all source domain registers
            data_in_stage1 <= 1'b0;
            sel_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
            src_demux_stage1 <= 4'b0;
            valid_src_stage1 <= 1'b0;
            src_demux_stage2 <= 4'b0;
            valid_src_stage2 <= 1'b0;
        end else begin
            // Pipeline Stage 1
            data_in_stage1 <= data_in;
            sel_stage1 <= sel;
            valid_stage1 <= data_valid;
            
            // Pipeline Stage 2 (Demux operation)
            src_demux_stage1 <= 4'b0;
            if (valid_stage1) begin
                src_demux_stage1[sel_stage1] <= data_in_stage1;
            end
            valid_src_stage1 <= valid_stage1;
            
            // Pipeline Stage 3 (Ready for CDC)
            src_demux_stage2 <= src_demux_stage1;
            valid_src_stage2 <= valid_src_stage1;
        end
    end
    
    // Destination domain pipeline (dst_clk domain) - 合并所有dst_clk触发的always块
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all destination domain registers
            meta_stage1 <= 4'b0;
            valid_meta_stage1 <= 1'b0;
            meta_stage2 <= 4'b0;
            valid_meta_stage2 <= 1'b0;
            sync_out <= 4'b0;
            sync_valid <= 1'b0;
        end else begin
            // First synchronization stage
            meta_stage1 <= src_demux_stage2;
            valid_meta_stage1 <= valid_src_stage2;
            
            // Second synchronization stage
            meta_stage2 <= meta_stage1;
            valid_meta_stage2 <= valid_meta_stage1;
            
            // Output stage
            sync_out <= meta_stage2;
            sync_valid <= valid_meta_stage2;
        end
    end
endmodule