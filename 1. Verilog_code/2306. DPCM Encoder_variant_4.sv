//SystemVerilog
module dpcm_encoder (
    input            clock,
    input            reset_n,
    input      [7:0] sample_in,
    input            sample_valid,
    output reg [7:0] dpcm_out,
    output reg       dpcm_valid,
    output reg [7:0] predicted_value
);
    // Pipeline stage registers
    reg [7:0] sample_stage1;
    reg       valid_stage1;
    reg [7:0] sample_stage2;
    reg       valid_stage2;
    reg [7:0] previous_sample;
    reg [7:0] predicted_stage1;
    reg [7:0] difference_stage2;
    
    // Simple prediction function (just uses previous sample)
    function [7:0] predict;
        input [7:0] prev;
        begin
            predict = prev; // Simple predictor
        end
    endfunction

    // Combined pipeline processing with merged always blocks
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all pipeline registers
            sample_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
            previous_sample <= 8'h80; // Mid-level
            predicted_stage1 <= 8'h80;
            sample_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            difference_stage2 <= 8'h0;
            dpcm_out <= 8'h0;
            dpcm_valid <= 1'b0;
            predicted_value <= 8'h80;
        end else begin
            // Stage 1: Input registration and prediction
            sample_stage1 <= sample_in;
            valid_stage1 <= sample_valid;
            predicted_stage1 <= predict(previous_sample);
            
            // Stage 2: Difference calculation
            sample_stage2 <= sample_stage1;
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                difference_stage2 <= sample_stage1 - predicted_stage1;
            end
            
            // Stage 3: Output registration
            dpcm_valid <= valid_stage2;
            if (valid_stage2) begin
                dpcm_out <= difference_stage2;
                predicted_value <= predicted_stage1;
                previous_sample <= sample_stage2; // Update previous sample
            end
        end
    end
endmodule