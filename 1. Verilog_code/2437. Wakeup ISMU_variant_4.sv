//SystemVerilog
module wakeup_ismu(
    input wire clk,
    input wire rst_n,
    input wire sleep_mode,
    input wire [7:0] int_src,
    input wire [7:0] wakeup_mask,
    output reg wakeup,
    output reg [7:0] pending_int
);
    // Stage 1 signals
    reg sleep_mode_stage1;
    reg [7:0] int_src_stage1;
    reg [7:0] wakeup_mask_stage1;
    reg valid_stage1;
    
    // Stage 2 signals
    reg sleep_mode_stage2;
    reg [7:0] wake_sources_stage2;
    reg [7:0] int_src_stage2;
    reg valid_stage2;
    
    // Pre-compute signals for balancing logic paths
    wire [7:0] masked_int;
    
    // Combinational logic
    assign masked_int = int_src_stage1 & ~wakeup_mask_stage1;
    
    // Sequential logic - merged all posedge clk or negedge rst_n blocks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 reset
            sleep_mode_stage1 <= 1'b0;
            int_src_stage1 <= 8'h0;
            wakeup_mask_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
            
            // Stage 2 reset
            sleep_mode_stage2 <= 1'b0;
            wake_sources_stage2 <= 8'h0;
            int_src_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            
            // Stage 3 reset
            wakeup <= 1'b0;
            pending_int <= 8'h0;
        end else begin
            // Stage 1 logic
            sleep_mode_stage1 <= sleep_mode;
            int_src_stage1 <= int_src;
            wakeup_mask_stage1 <= wakeup_mask;
            valid_stage1 <= 1'b1;
            
            // Stage 2 logic
            sleep_mode_stage2 <= sleep_mode_stage1;
            wake_sources_stage2 <= masked_int;
            int_src_stage2 <= int_src_stage1;
            valid_stage2 <= valid_stage1;
            
            // Stage 3 logic
            if (valid_stage2) begin
                // Directly compute wake condition in the sequential block
                wakeup <= sleep_mode_stage2 & (|wake_sources_stage2);
                
                // Use efficient bitwise OR for pending interrupts
                pending_int <= pending_int | int_src_stage2;
            end
        end
    end
endmodule