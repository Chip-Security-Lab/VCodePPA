//SystemVerilog
module moving_avg_filter #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2  // log2(DEPTH)
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o
);
    // Pipeline stage 1: Shift register and input sample
    reg [DATA_W-1:0] samples [DEPTH-1:0];
    reg [DATA_W-1:0] data_i_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Sum calculation
    reg [DATA_W+LOG2_DEPTH-1:0] sum_stage2;
    reg [DATA_W-1:0] oldest_sample_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Division and output
    reg [DATA_W+LOG2_DEPTH-1:0] sum_stage3;
    reg valid_stage3;
    
    integer i;
    
    // Stage 1: Shift register and input sample
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                samples[i] <= 0;
            data_i_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (enable) begin
            // Shift in new sample
            for (i = DEPTH-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= data_i;
            data_i_stage1 <= data_i;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Sum calculation
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_stage2 <= 0;
            oldest_sample_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            sum_stage2 <= sum_stage2 - samples[DEPTH-1] + data_i_stage1;
            oldest_sample_stage2 <= samples[DEPTH-1];
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Division and output
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_stage3 <= 0;
            data_o <= 0;
            valid_stage3 <= 0;
        end else if (valid_stage2) begin
            sum_stage3 <= sum_stage2;
            data_o <= sum_stage2 >> LOG2_DEPTH;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
endmodule