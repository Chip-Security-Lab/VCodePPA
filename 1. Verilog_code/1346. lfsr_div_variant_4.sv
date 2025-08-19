//SystemVerilog
module lfsr_div #(parameter POLY=8'hB4) (
    input clk, rst,
    output reg clk_out
);
    // Stage 1: LFSR feedback calculation
    reg [7:0] lfsr_stage1;
    reg valid_stage1;
    wire feedback_stage1 = lfsr_stage1[7];
    wire [7:0] xor_mask_stage1 = feedback_stage1 ? POLY : 8'h0;
    
    // Stage 2: LFSR update calculation
    reg [7:0] lfsr_stage2;
    reg [7:0] xor_mask_stage2;
    reg valid_stage2;
    wire [7:0] shifted_stage2 = {lfsr_stage2[6:0], 1'b0};
    wire [7:0] lfsr_next_stage2 = shifted_stage2 ^ xor_mask_stage2;
    
    // Stage 3: Comparison logic
    reg [7:0] lfsr_stage3;
    reg valid_stage3;
    wire compare_result_stage3 = (lfsr_stage3 == 8'h00);
    
    // Pipeline control
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline stages
            lfsr_stage1 <= 8'hFF;
            valid_stage1 <= 1'b1;
            
            lfsr_stage2 <= 8'h00;
            xor_mask_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
            
            lfsr_stage3 <= 8'h00;
            valid_stage3 <= 1'b0;
            
            clk_out <= 1'b0;
        end else begin
            // Stage 1: Capture initial LFSR value and calculate feedback
            lfsr_stage1 <= lfsr_stage3 == 8'h00 ? 8'hFF : lfsr_next_stage2;
            valid_stage1 <= 1'b1;
            
            // Stage 2: Move feedback data to next stage
            lfsr_stage2 <= lfsr_stage1;
            xor_mask_stage2 <= xor_mask_stage1;
            valid_stage2 <= valid_stage1;
            
            // Stage 3: Move update data to next stage
            lfsr_stage3 <= lfsr_next_stage2;
            valid_stage3 <= valid_stage2;
            
            // Output stage
            clk_out <= valid_stage3 && compare_result_stage3;
        end
    end
endmodule