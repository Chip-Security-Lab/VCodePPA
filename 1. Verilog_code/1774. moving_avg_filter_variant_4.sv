//SystemVerilog
module moving_avg_filter #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2  // log2(DEPTH)
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o,
    output wire valid_o
);
    // Pipeline stage registers
    reg [DATA_W-1:0] samples [DEPTH-1:0];
    reg [DATA_W+LOG2_DEPTH-1:0] sum_stage1;
    reg [DATA_W+LOG2_DEPTH-1:0] sum_stage2;
    reg [DATA_W-1:0] data_i_stage1;
    reg [DATA_W-1:0] oldest_sample;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    assign valid_o = valid_stage3;
    
    integer i;
    
    // Stage 1: Sample shifting and capturing oldest sample
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                samples[i] <= 0;
            oldest_sample <= 0;
            data_i_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (enable) begin
            // Store input for next stage
            data_i_stage1 <= data_i;
            
            // Capture oldest sample before it's overwritten
            oldest_sample <= samples[DEPTH-1];
            
            // Shift samples
            for (i = DEPTH-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= data_i;
            
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 0;
        end
    end
    
    // Stage 2: Sum calculation
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_stage1 <= 0;
            valid_stage2 <= 0;
        end else if (enable) begin
            if (valid_stage1) begin
                // Update sum by subtracting oldest and adding newest
                sum_stage1 <= sum_stage1 - oldest_sample + data_i_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 0;
            end
        end else begin
            valid_stage2 <= 0;
        end
    end
    
    // Stage 3: Division and output
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_stage2 <= 0;
            data_o <= 0;
            valid_stage3 <= 0;
        end else if (enable) begin
            if (valid_stage2) begin
                // Store sum for next stage
                sum_stage2 <= sum_stage1;
                // Perform division (right shift)
                data_o <= sum_stage1 >> LOG2_DEPTH;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 0;
            end
        end else begin
            valid_stage3 <= 0;
        end
    end
endmodule