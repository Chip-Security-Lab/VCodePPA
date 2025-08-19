//SystemVerilog
module wakeup_ismu(
    input clk, rst_n,
    input sleep_mode,
    input [7:0] int_src,
    input [7:0] wakeup_mask,
    output reg wakeup,
    output reg [7:0] pending_int
);
    // Stage 1 registers - optimized for better timing
    reg [7:0] int_src_stage1;
    reg [7:0] wakeup_mask_stage1;
    reg sleep_mode_stage1;
    reg valid_stage1;
    
    // Stage 2 registers - using parallel computation
    reg [7:0] wake_sources_stage2;
    reg [7:0] int_src_stage2;
    reg sleep_mode_stage2;
    reg valid_stage2;
    reg has_wake_source_stage2; // Pre-computed wake status flag
    
    // Stage 1: Input Capture with parallel validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage1 <= 8'h0;
            wakeup_mask_stage1 <= 8'h0;
            sleep_mode_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            int_src_stage1 <= int_src;
            wakeup_mask_stage1 <= wakeup_mask;
            sleep_mode_stage1 <= sleep_mode;
            valid_stage1 <= 1'b1;  // Always valid after reset
        end
    end
    
    // Stage 2: Optimized wake source computation with pre-calculated status
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wake_sources_stage2 <= 8'h0;
            int_src_stage2 <= 8'h0;
            sleep_mode_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            has_wake_source_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // More efficient masking for wake sources
            wake_sources_stage2 <= int_src_stage1 & (~wakeup_mask_stage1);
            int_src_stage2 <= int_src_stage1;
            sleep_mode_stage2 <= sleep_mode_stage1;
            valid_stage2 <= 1'b1;
            
            // Pre-compute wake status - reduces logic depth in stage 3
            has_wake_source_stage2 <= |(int_src_stage1 & (~wakeup_mask_stage1));
        end
    end
    
    // Stage 3: Optimized output generation with reduced comparison chain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup <= 1'b0;
            pending_int <= 8'h0;
        end else if (valid_stage2) begin
            // Efficient interrupt status tracking
            pending_int <= pending_int | int_src_stage2;
            
            // Simplified wake-up logic using pre-computed status
            wakeup <= sleep_mode_stage2 & has_wake_source_stage2;
        end
    end
endmodule