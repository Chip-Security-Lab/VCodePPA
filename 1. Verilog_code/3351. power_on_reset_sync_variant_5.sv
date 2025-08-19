//SystemVerilog
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: Power-On Reset Synchronizer with Enhanced Pipeline Architecture
// Module Name: power_on_reset_sync
// Target Devices: FPGA/ASIC
// Tool Versions: 
// Description: Provides synchronized power-on reset signal with improved pipeline structure
// 
// Dependencies: None
// 
// Revision: 2.0
// Additional Comments: Compliant with IEEE 1364-2005 Verilog standard
//                     Converted to pipeline architecture for improved throughput
// 
//////////////////////////////////////////////////////////////////////////////////

module power_on_reset_sync (
    input  wire clk,         // System clock
    input  wire ext_rst_n,   // External asynchronous reset (active low)
    output wire por_rst_n    // Power-on reset output (active low)
);
    // ------ Pipeline stage valid signals ------
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // ------ Reset synchronization pipeline ------
    reg [3:0] ext_rst_sync_pipe;  // Extended external reset synchronization pipeline
    
    // ------ POR counter pipeline registers ------
    reg [2:0] por_count_stage1;   // Stage 1 counter
    reg [2:0] por_count_stage2;   // Stage 2 counter
    reg [2:0] por_count_stage3;   // Stage 3 counter
    
    // ------ Pipeline stage completion flags ------
    reg por_complete_stage1;
    reg por_complete_stage2;
    reg por_complete_stage3;
    
    // ------ Output stage registers ------
    reg por_rst_n_stage1;
    reg por_rst_n_stage2;
    reg por_rst_n_reg;
    
    // ------ Reset initialization ------
    initial begin
        por_count_stage1 = 3'b000;
        por_count_stage2 = 3'b000;
        por_count_stage3 = 3'b000;
        por_complete_stage1 = 1'b0;
        por_complete_stage2 = 1'b0;
        por_complete_stage3 = 1'b0;
        ext_rst_sync_pipe = 4'b0000;
        stage1_valid = 1'b0;
        stage2_valid = 1'b0;
        stage3_valid = 1'b0;
        por_rst_n_stage1 = 1'b0;
        por_rst_n_stage2 = 1'b0;
        por_rst_n_reg = 1'b0;
    end
    
    // ------ Stage 1: External reset synchronization path ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_sync_pipe <= 4'b0000;
            stage1_valid <= 1'b0;
        end else begin
            // Four-stage synchronizer pipeline for external reset
            ext_rst_sync_pipe <= {ext_rst_sync_pipe[2:0], 1'b1};
            stage1_valid <= 1'b1;
        end
    end
    
    // ------ Stage 2: POR counter first pipeline stage ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_count_stage1 <= 3'b000;
            por_complete_stage1 <= 1'b0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid) begin
            if (!por_complete_stage1) begin
                if (por_count_stage1 < 3'b011) begin
                    // Handle first half of counting in stage 1
                    por_count_stage1 <= por_count_stage1 + 1'b1;
                    por_complete_stage1 <= 1'b0;
                end else begin
                    // Partial completion for first pipeline stage
                    por_complete_stage1 <= 1'b1;
                end
            end
            stage2_valid <= stage1_valid;
        end
    end
    
    // ------ Stage 3: POR counter second pipeline stage ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_count_stage2 <= 3'b000;
            por_complete_stage2 <= 1'b0;
            stage3_valid <= 1'b0;
        end else if (stage2_valid) begin
            // Pass stage 1 values to stage 2 if not completed
            if (por_complete_stage1) begin
                por_count_stage2 <= por_count_stage1;
                // Continue counting in second pipeline stage
                if (por_count_stage2 < 3'b111) begin
                    por_count_stage2 <= por_count_stage2 + 1'b1;
                    por_complete_stage2 <= (por_count_stage2 >= 3'b110);
                end else begin
                    por_complete_stage2 <= 1'b1;
                end
            end else begin
                por_count_stage2 <= por_count_stage1;
                por_complete_stage2 <= por_complete_stage1;
            end
            stage3_valid <= stage2_valid;
        end
    end
    
    // ------ Stage 4: Final counter stage and stabilization ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_count_stage3 <= 3'b000;
            por_complete_stage3 <= 1'b0;
        end else if (stage3_valid) begin
            // Final counter stage processing
            por_count_stage3 <= por_count_stage2;
            por_complete_stage3 <= por_complete_stage2;
        end
    end
    
    // ------ Pipeline output stage 1 ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_rst_n_stage1 <= 1'b0;
        end else begin
            // First stage of output generation combining synchronized external reset and POR completion
            por_rst_n_stage1 <= ext_rst_sync_pipe[2] & por_complete_stage2;
        end
    end
    
    // ------ Pipeline output stage 2 ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_rst_n_stage2 <= 1'b0;
        end else begin
            // Second stage of output generation - additional filtering
            por_rst_n_stage2 <= por_rst_n_stage1 & ext_rst_sync_pipe[3];
        end
    end
    
    // ------ Final output stage ------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_rst_n_reg <= 1'b0;
        end else begin
            // Final output register with additional stabilization
            por_rst_n_reg <= por_rst_n_stage2 & por_complete_stage3;
        end
    end
    
    // ------ Output signal assignment ------
    assign por_rst_n = por_rst_n_reg;

endmodule