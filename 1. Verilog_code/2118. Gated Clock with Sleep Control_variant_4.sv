//SystemVerilog
module gated_clk_sleep(
    input clk_src,
    input sleep,
    input enable,
    input rst_n,         // Reset signal for pipeline control
    output gated_clk,
    output valid_out     // Valid signal to indicate clock gating status is valid
);
    // Pipeline stage 1 registers (sleep signal capture)
    reg sleep_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers (enable latch)
    reg enable_latch_stage2;
    reg sleep_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers (sleep processing)
    reg sleep_processed_stage3;
    reg enable_processed_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 registers (pre-gating computation)
    reg enable_gated_stage4;
    reg valid_stage4;
    
    // Pipeline stage 5 registers (final gating stage)
    reg enable_final_stage5;
    reg valid_stage5;
    
    // Stage 1: Capture sleep signal on negative edge
    always @(negedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            sleep_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            sleep_stage1 <= sleep;
            valid_stage1 <= 1'b1;  // Data is valid after first stage
        end
    end
    
    // Stage 2: Process enable signal and propagate sleep
    always @(negedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            enable_latch_stage2 <= 1'b0;
            sleep_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            enable_latch_stage2 <= enable;
            sleep_stage2 <= sleep_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Apply sleep control logic
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            sleep_processed_stage3 <= 1'b0;
            enable_processed_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            sleep_processed_stage3 <= sleep_stage2;
            enable_processed_stage3 <= sleep_stage2 ? 1'b0 : enable_latch_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Compute initial gating condition
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            enable_gated_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            enable_gated_stage4 <= enable_processed_stage3 & ~sleep_processed_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Stage 5: Final stage for clock gating
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            enable_final_stage5 <= 1'b0;
            valid_stage5 <= 1'b0;
        end else begin
            enable_final_stage5 <= enable_gated_stage4;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Final output: gated clock and valid signal
    assign gated_clk = clk_src & enable_final_stage5;
    assign valid_out = valid_stage5;
endmodule