//SystemVerilog
module tff_clear (
    input clk, clr,
    input en,           // Enable signal for pipeline control
    output reg valid_out, // Pipeline stage valid signal
    output reg q
);

    // Increased pipeline stage registers
    reg stage1_valid;
    reg stage1_toggle;
    reg stage2_valid;
    reg stage2_value;
    reg stage3_valid;
    reg stage3_value;
    reg stage4_valid;
    reg stage4_value;

    // Combined pipeline stages with same trigger conditions
    always @(posedge clk) begin
        if (clr) begin
            // Reset all pipeline stages
            stage1_valid <= 1'b0;
            stage1_toggle <= 1'b0;
            stage2_valid <= 1'b0;
            stage2_value <= 1'b0;
            stage3_valid <= 1'b0;
            stage3_value <= 1'b0;
            stage4_valid <= 1'b0;
            stage4_value <= 1'b0;
            valid_out <= 1'b0;
            q <= 1'b0;
        end else begin
            // Stage 1: Capture enable signal
            if (en) begin
                stage1_valid <= 1'b1;
                stage1_toggle <= ~q;  // Compute next state
            end else begin
                stage1_valid <= 1'b0;
                // Keep previous value
            end
            
            // Stage 2: First processing stage
            stage2_valid <= stage1_valid;
            stage2_value <= stage1_toggle;
            
            // Stage 3: Second processing stage
            stage3_valid <= stage2_valid;
            stage3_value <= stage2_value;
            
            // Stage 4: Final preparation stage
            stage4_valid <= stage3_valid;
            stage4_value <= stage3_value;
            
            // Output stage
            valid_out <= stage4_valid;
            if (stage4_valid)
                q <= stage4_value;
        end
    end

endmodule