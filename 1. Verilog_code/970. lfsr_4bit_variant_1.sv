//SystemVerilog
module lfsr_4bit (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output wire [3:0] pseudo_random,
    output wire valid_out
);
    // Pipeline registers for LFSR stages
    reg [3:0] lfsr_stage1;
    reg [3:0] lfsr_stage2;
    reg [3:0] lfsr_stage3;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Feedback calculation for each stage
    wire feedback_stage1;
    wire feedback_stage2;
    wire feedback_stage3;
    
    // Stage 1 feedback calculation
    assign feedback_stage1 = lfsr_stage1[0] ^ lfsr_stage1[2];
    
    // Stage 2 feedback calculation
    assign feedback_stage2 = lfsr_stage2[0] ^ lfsr_stage2[2];
    
    // Stage 3 feedback calculation
    assign feedback_stage3 = lfsr_stage3[0] ^ lfsr_stage3[2];
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage1 <= 4'b1000;  // Initial seed
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            lfsr_stage1 <= {feedback_stage1, lfsr_stage1[3:1]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            lfsr_stage2 <= {feedback_stage2, lfsr_stage2[3:1]};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end
        else if (enable) begin
            lfsr_stage3 <= {feedback_stage3, lfsr_stage3[3:1]};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign pseudo_random = lfsr_stage3;
    assign valid_out = valid_stage3;
    
endmodule