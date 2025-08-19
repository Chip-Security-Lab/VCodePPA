//SystemVerilog
module AdaptiveThreshold #(parameter W=8) (
    input clk,
    input rst_n,
    input [W-1:0] signal,
    output reg threshold,
    output reg valid_out
);

    // Pipeline stage 1: Sum calculation
    reg [W+3:0] sum_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Threshold calculation
    reg [W+3:0] sum_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Final output
    reg [W+3:0] sum_stage3;
    
    // Stage 1: Sum calculation - optimized for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end else begin
            sum_stage1 <= sum_stage1 + signal - sum_stage1[W+3:W];
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Intermediate calculation - separated for better modularity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 0;
        end else begin
            sum_stage2 <= sum_stage1;
        end
    end
    
    // Stage 2: Valid signal propagation - separated for better modularity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Sum propagation - separated for better modularity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage3 <= 0;
        end else begin
            sum_stage3 <= sum_stage2;
        end
    end
    
    // Stage 3: Threshold calculation - separated for better modularity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold <= 0;
        end else begin
            threshold <= sum_stage2[W+3:W] >> 2;
        end
    end
    
    // Stage 3: Valid output - separated for better modularity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
        end
    end

endmodule