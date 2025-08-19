//SystemVerilog
module RangeDetector_StateHold #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg state_flag
);
    // Stage 1 - Split data and threshold for comparison
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] threshold_stage1;
    
    // Stage 2 - Perform comparison operations
    reg data_gt_threshold_stage2;
    reg data_lt_threshold_stage2;
    
    // Stage 3 - Intermediate logic processing
    reg data_gt_threshold_stage3;
    reg data_lt_threshold_stage3;
    
    // Stage 4 - Final state determination
    reg data_gt_valid_stage4;
    reg data_lt_valid_stage4;
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_stage1 <= 0;
            threshold_stage1 <= 0;
        end
        else begin
            data_in_stage1 <= data_in;
            threshold_stage1 <= threshold;
        end
    end
    
    // Second pipeline stage - perform comparisons
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_gt_threshold_stage2 <= 0;
            data_lt_threshold_stage2 <= 0;
        end
        else begin
            data_gt_threshold_stage2 <= data_in_stage1 > threshold_stage1;
            data_lt_threshold_stage2 <= data_in_stage1 < threshold_stage1;
        end
    end
    
    // Third pipeline stage - process comparison results
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_gt_threshold_stage3 <= 0;
            data_lt_threshold_stage3 <= 0;
        end
        else begin
            data_gt_threshold_stage3 <= data_gt_threshold_stage2;
            data_lt_threshold_stage3 <= data_lt_threshold_stage2;
        end
    end
    
    // Fourth pipeline stage - validate comparison results
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_gt_valid_stage4 <= 0;
            data_lt_valid_stage4 <= 0;
        end
        else begin
            data_gt_valid_stage4 <= data_gt_threshold_stage3;
            data_lt_valid_stage4 <= data_lt_threshold_stage3;
        end
    end
    
    // Fifth pipeline stage - update state flag
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_flag <= 0;
        end
        else begin
            if(data_gt_valid_stage4) state_flag <= 1;
            else if(data_lt_valid_stage4) state_flag <= 0;
        end
    end
endmodule