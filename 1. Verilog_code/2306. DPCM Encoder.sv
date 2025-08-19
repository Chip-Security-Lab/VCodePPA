module dpcm_encoder (
    input            clock,
    input            reset_n,
    input      [7:0] sample_in,
    input            sample_valid,
    output reg [7:0] dpcm_out,
    output reg       dpcm_valid,
    output reg [7:0] predicted_value
);
    reg [7:0] previous_sample;
    
    // Simple prediction function (just uses previous sample)
    function [7:0] predict;
        input [7:0] prev;
        begin
            predict = prev; // Simple predictor
        end
    endfunction

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            previous_sample <= 8'h80; // Mid-level
            predicted_value <= 8'h80;
            dpcm_out <= 0;
            dpcm_valid <= 0;
        end else if (sample_valid) begin
            predicted_value <= predict(previous_sample);
            dpcm_out <= sample_in - predicted_value;
            previous_sample <= sample_in;
            dpcm_valid <= 1;
        end else begin
            dpcm_valid <= 0;
        end
    end
endmodule