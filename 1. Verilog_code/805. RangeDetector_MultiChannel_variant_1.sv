//SystemVerilog
module RangeDetector_MultiChannel #(
    parameter WIDTH = 8,
    parameter CHANNELS = 4
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] thresholds [CHANNELS*2-1:0],
    input [$clog2(CHANNELS)-1:0] ch_sel,
    input valid_in,
    output reg valid_out,
    output reg out_flag
);

    // Stage 1 registers
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] lower_thresh_stage1;
    reg [WIDTH-1:0] upper_thresh_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg lower_compare_stage2;
    reg upper_compare_stage2;
    reg valid_stage2;
    
    // Pipeline Stage 1: Register inputs and select thresholds
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            lower_thresh_stage1 <= 0;
            upper_thresh_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
            lower_thresh_stage1 <= thresholds[ch_sel*2];
            upper_thresh_stage1 <= thresholds[ch_sel*2+1];
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline Stage 2: Perform comparisons
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_compare_stage2 <= 0;
            upper_compare_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            lower_compare_stage2 <= (data_in_stage1 >= lower_thresh_stage1);
            upper_compare_stage2 <= (data_in_stage1 <= upper_thresh_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Generate output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_flag <= 0;
            valid_out <= 0;
        end else begin
            out_flag <= lower_compare_stage2 && upper_compare_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule