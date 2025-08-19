//SystemVerilog
module RangeDetector_MultiChannel #(
    parameter WIDTH = 8,
    parameter CHANNELS = 4
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] thresholds [CHANNELS*2-1:0],
    input [$clog2(CHANNELS)-1:0] ch_sel,
    output reg out_flag
);
    // Pipeline registers for threshold selection and data
    reg [WIDTH-1:0] lower_thresh_r, upper_thresh_r;
    reg [WIDTH-1:0] data_in_r;
    
    // Pipeline registers for comparison results
    reg lower_comp_r, upper_comp_r;
    
    // First stage: Select threshold values and register input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_thresh_r <= 0;
            upper_thresh_r <= 0;
            data_in_r <= 0;
        end else begin
            lower_thresh_r <= thresholds[ch_sel*2];
            upper_thresh_r <= thresholds[ch_sel*2+1];
            data_in_r <= data_in;
        end
    end
    
    // Second stage: Perform comparisons
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_comp_r <= 0;
            upper_comp_r <= 0;
        end else begin
            lower_comp_r <= (data_in_r >= lower_thresh_r);
            upper_comp_r <= (data_in_r <= upper_thresh_r);
        end
    end
    
    // Final stage: Combine results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_flag <= 0;
        end else begin
            out_flag <= lower_comp_r && upper_comp_r;
        end
    end
endmodule