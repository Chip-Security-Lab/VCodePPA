//SystemVerilog
module Hamming_Error_Injection(
    input clk,
    input rst_n,
    input valid_in,
    input error_en,
    input [3:0] error_position,
    input [7:0] clean_code,
    output reg [7:0] corrupted_code,
    output reg valid_out
);
    // Stage 1: Pre-decode error position
    reg [7:0] error_mask_partial;
    reg [1:0] error_position_high_stage1;
    reg [1:0] error_position_low_stage1;
    reg error_en_stage1;
    reg [7:0] clean_code_stage1;
    reg valid_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_position_high_stage1 <= 2'b0;
            error_position_low_stage1 <= 2'b0;
            error_en_stage1 <= 1'b0;
            clean_code_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            error_position_high_stage1 <= error_position[3:2];
            error_position_low_stage1 <= error_position[1:0];
            error_en_stage1 <= error_en;
            clean_code_stage1 <= clean_code;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 1.5: Complete error mask calculation
    reg [7:0] error_mask_stage1_5;
    reg error_en_stage1_5;
    reg [7:0] clean_code_stage1_5;
    reg valid_stage1_5;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_mask_stage1_5 <= 8'b0;
            error_en_stage1_5 <= 1'b0;
            clean_code_stage1_5 <= 8'b0;
            valid_stage1_5 <= 1'b0;
        end
        else begin
            // Two-step shift calculation to reduce critical path
            error_mask_partial = (4'b0001 << error_position_low_stage1);
            error_mask_stage1_5 <= (error_mask_partial << {error_position_high_stage1, 2'b00});
            error_en_stage1_5 <= error_en_stage1;
            clean_code_stage1_5 <= clean_code_stage1;
            valid_stage1_5 <= valid_stage1;
        end
    end
    
    // Stage 2: Apply error mask to clean code
    reg [7:0] corrupted_code_stage2;
    reg valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            corrupted_code_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            corrupted_code_stage2 <= error_en_stage1_5 ? 
                                    (clean_code_stage1_5 ^ error_mask_stage1_5) : 
                                    clean_code_stage1_5;
            valid_stage2 <= valid_stage1_5;
        end
    end
    
    // Output stage: Register final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            corrupted_code <= 8'b0;
            valid_out <= 1'b0;
        end
        else begin
            corrupted_code <= corrupted_code_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule