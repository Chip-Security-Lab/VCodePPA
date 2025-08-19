//SystemVerilog
module WaveletFilter #(parameter W=8) (
    input clk,
    input rst_n,
    input [W-1:0] din,
    output reg [W-1:0] approx, detail
);
    // Stage 1: Input registration and storage
    reg [W-1:0] din_stage1;
    reg [W-1:0] prev_sample_stage1;
    
    // Stage 2: Computation intermediates
    reg [W-1:0] sum_stage2;
    reg [W-1:0] diff_stage2;
    reg [W-1:0] din_stage2;
    
    // Stage 3: Final output calculation
    reg [W-1:0] shifted_sum_stage3;
    reg [W-1:0] diff_stage3;
    
    // Pipeline implementation
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset logic
            din_stage1 <= 0;
            prev_sample_stage1 <= 0;
            sum_stage2 <= 0;
            diff_stage2 <= 0;
            din_stage2 <= 0;
            shifted_sum_stage3 <= 0;
            diff_stage3 <= 0;
            approx <= 0;
            detail <= 0;
        end else begin
            // Stage 1: Register inputs and update previous sample
            din_stage1 <= din;
            prev_sample_stage1 <= din_stage1;
            
            // Stage 2: Perform addition and subtraction operations
            sum_stage2 <= din_stage1 + prev_sample_stage1;
            diff_stage2 <= din_stage1 - prev_sample_stage1;
            din_stage2 <= din_stage1;
            
            // Stage 3: Perform shift operation and prepare final outputs
            shifted_sum_stage3 <= sum_stage2 >> 1;
            diff_stage3 <= diff_stage2;
            
            // Output stage: Register final results
            approx <= shifted_sum_stage3;
            detail <= diff_stage3;
        end
    end
endmodule