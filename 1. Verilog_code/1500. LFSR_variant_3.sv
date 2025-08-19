//SystemVerilog
module lfsr #(parameter [15:0] POLY = 16'h8016) (
    input wire clock, reset,
    input wire enable,
    output wire [15:0] lfsr_out,
    output wire sequence_bit,
    output wire valid_out
);
    // Stage 1 registers - Initial input stage
    reg [15:0] lfsr_reg_stage1;
    reg valid_stage1;
    
    // Stage 2 registers - Feedback calculation stage
    reg [15:0] lfsr_reg_stage2;
    reg valid_stage2;
    reg feedback_stage2;
    
    // Stage 3 registers - Upper half shift stage
    reg [7:0] upper_half_stage3;
    reg [7:0] lower_half_stage3;
    reg valid_stage3;
    reg feedback_stage3;
    
    // Stage 4 registers - Lower half shift and combine stage
    reg [15:0] lfsr_reg_stage4;
    reg valid_stage4;
    
    // Stage 5 registers (final output stage)
    reg [15:0] lfsr_reg_stage5;
    reg valid_stage5;
    
    // Internal signals
    wire [7:0] next_upper_half;
    wire [7:0] next_lower_half;
    wire feedback;
    
    // Calculate feedback based on polynomial
    assign feedback = ^(lfsr_reg_stage1 & POLY);
    
    // Calculate next LFSR parts
    assign next_upper_half = lfsr_reg_stage2[14:7];
    assign next_lower_half = {lfsr_reg_stage2[6:0], feedback_stage3};
    
    // Stage 1: Initial input stage
    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg_stage1 <= 16'h0001;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            lfsr_reg_stage1 <= lfsr_reg_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Feedback calculation stage
    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg_stage2 <= 16'h0000;
            feedback_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (enable) begin
            lfsr_reg_stage2 <= lfsr_reg_stage1;
            feedback_stage2 <= feedback;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Upper half shift stage
    always @(posedge clock) begin
        if (reset) begin
            upper_half_stage3 <= 8'h00;
            lower_half_stage3 <= 8'h00;
            feedback_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (enable) begin
            upper_half_stage3 <= next_upper_half;
            lower_half_stage3 <= lfsr_reg_stage2[7:0];
            feedback_stage3 <= feedback_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Lower half shift and combine stage
    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg_stage4 <= 16'h0000;
            valid_stage4 <= 1'b0;
        end else if (enable) begin
            lfsr_reg_stage4 <= {upper_half_stage3, next_lower_half};
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Stage 5: Final output stage
    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg_stage5 <= 16'h0000;
            valid_stage5 <= 1'b0;
        end else if (enable) begin
            lfsr_reg_stage5 <= lfsr_reg_stage4;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Output assignments
    assign lfsr_out = lfsr_reg_stage5;
    assign sequence_bit = lfsr_reg_stage5[15];
    assign valid_out = valid_stage5;
endmodule