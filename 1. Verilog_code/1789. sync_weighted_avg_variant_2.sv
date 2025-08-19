//SystemVerilog
module sync_weighted_avg #(
    parameter DW = 12,
    parameter WEIGHTS = 3
)(
    input clk, rstn,
    input [DW-1:0] sample_in,
    input [7:0] weights [WEIGHTS-1:0],
    output reg [DW-1:0] filtered_out
);
    // Sample delay line registers
    reg [DW-1:0] samples [WEIGHTS-1:0];
    
    // Pipeline stage 1: Store multiplication results
    reg [DW+8-1:0] mult_results_stage1 [WEIGHTS-1:0];
    reg [7:0] weights_stage1 [WEIGHTS-1:0];
    
    // Pipeline stage 2: Partial sums (divide and conquer approach)
    reg [DW+8-1:0] partial_sum1_stage2;
    reg [DW+8-1:0] partial_sum2_stage2;
    reg [7:0] weight_sum1_stage2;
    reg [7:0] weight_sum2_stage2;
    
    // Pipeline stage 3: Final sum
    reg [DW+8-1:0] weighted_sum_stage3;
    reg [7:0] weight_sum_stage3;
    
    // Pipeline stage 4: Division preparation
    reg [DW+8-1:0] weighted_sum_stage4;
    reg [7:0] weight_sum_stage4;
    
    integer i;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset sample delay line
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                samples[i] <= 0;
                mult_results_stage1[i] <= 0;
                weights_stage1[i] <= 0;
            end
            
            // Reset pipeline stages
            partial_sum1_stage2 <= 0;
            partial_sum2_stage2 <= 0;
            weight_sum1_stage2 <= 0;
            weight_sum2_stage2 <= 0;
            
            weighted_sum_stage3 <= 0;
            weight_sum_stage3 <= 0;
            
            weighted_sum_stage4 <= 0;
            weight_sum_stage4 <= 0;
            
            filtered_out <= 0;
        end else begin
            // Stage 0: Shift samples through delay line
            for (i = WEIGHTS-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= sample_in;
            
            // Stage 1: Compute all multiplications in parallel
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                mult_results_stage1[i] <= samples[i] * weights[i];
                weights_stage1[i] <= weights[i];
            end
            
            // Stage 2: Calculate partial sums (split computation)
            partial_sum1_stage2 <= (WEIGHTS >= 2) ? (mult_results_stage1[0] + mult_results_stage1[1]) : mult_results_stage1[0];
            partial_sum2_stage2 <= (WEIGHTS >= 3) ? mult_results_stage1[2] : 0;
            weight_sum1_stage2 <= (WEIGHTS >= 2) ? (weights_stage1[0] + weights_stage1[1]) : weights_stage1[0];
            weight_sum2_stage2 <= (WEIGHTS >= 3) ? weights_stage1[2] : 0;
            
            // Stage 3: Merge partial results
            weighted_sum_stage3 <= partial_sum1_stage2 + partial_sum2_stage2;
            weight_sum_stage3 <= weight_sum1_stage2 + weight_sum2_stage2;
            
            // Stage 4: Prepare for division (extra pipeline stage for timing improvement)
            weighted_sum_stage4 <= weighted_sum_stage3;
            weight_sum_stage4 <= weight_sum_stage3;
            
            // Final stage: Normalize by sum of weights
            if (weight_sum_stage4 != 0) begin
                filtered_out <= weighted_sum_stage4 / weight_sum_stage4;
            end else begin
                filtered_out <= 0; // Avoid division by zero
            end
        end
    end
endmodule