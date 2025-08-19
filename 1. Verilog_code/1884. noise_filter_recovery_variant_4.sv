//SystemVerilog
module noise_filter_recovery #(
    parameter WIDTH = 10,
    parameter FILTER_DEPTH = 3
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] noisy_data,
    output reg [WIDTH-1:0] clean_data,
    output reg data_valid
);
    // Pipeline stage registers
    reg [WIDTH-1:0] history_stage1 [0:FILTER_DEPTH-1];
    reg [WIDTH-1:0] sorted_stage1 [0:FILTER_DEPTH-1];
    reg [WIDTH-1:0] sorted_stage2 [0:FILTER_DEPTH-1];
    reg [WIDTH-1:0] median_candidate;
    reg enable_stage1, enable_stage2, enable_stage3;
    
    integer i;
    
    // Pipeline Stage 1: Input capture and history shift
    always @(posedge clk) begin
        enable_stage1 <= enable;
        
        if (enable) begin
            // Shift history using efficient indexed shifting
            for (i = FILTER_DEPTH-1; i > 0; i = i - 1)
                history_stage1[i] <= history_stage1[i-1];
            history_stage1[0] <= noisy_data;
            
            // Copy to sorting array for next stage
            for (i = 0; i < FILTER_DEPTH; i = i + 1)
                sorted_stage1[i] <= history_stage1[i];
        end
    end
    
    // Pipeline Stage 2: Optimized sorting - first pass
    // Uses parallel comparison for better PPA characteristics
    always @(posedge clk) begin
        enable_stage2 <= enable_stage1;
        
        if (enable_stage1) begin
            // Efficient comparison network for FILTER_DEPTH=3
            // This implementation avoids nested loops for better timing
            if (sorted_stage1[0] > sorted_stage1[1]) begin
                sorted_stage2[0] <= sorted_stage1[1];
                sorted_stage2[1] <= sorted_stage1[0];
            end else begin
                sorted_stage2[0] <= sorted_stage1[0];
                sorted_stage2[1] <= sorted_stage1[1];
            end
            
            if (sorted_stage1[1] > sorted_stage1[2]) begin
                sorted_stage2[2] <= sorted_stage1[1];
                // Re-compare with the potentially larger value
                if (sorted_stage1[0] > sorted_stage1[2]) begin
                    sorted_stage2[1] <= sorted_stage1[2];
                    sorted_stage2[0] <= sorted_stage1[1];
                end else begin
                    // Maintain order from previous comparison
                    sorted_stage2[2] <= sorted_stage1[1];
                end
            end else begin
                sorted_stage2[2] <= sorted_stage1[2];
            end
        end
    end
    
    // Pipeline Stage 3: Final sorting and median selection
    // Direct median extraction without unnecessary comparisons
    always @(posedge clk) begin
        enable_stage3 <= enable_stage2;
        
        if (enable_stage2) begin
            // Find median directly using range checking
            // For FILTER_DEPTH=3, the median is at index 1
            median_candidate <= sorted_stage2[FILTER_DEPTH/2];
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (enable_stage3) begin
            // Output median value
            clean_data <= median_candidate;
            data_valid <= 1'b1;
        end else begin
            data_valid <= 1'b0;
        end
    end
endmodule