//SystemVerilog
module hamming_decoder_flags(
    input clk, rst_n,
    input [11:0] code_word,
    output reg [7:0] data_out,
    output reg error_fixed, double_error
);
    // Stage 1 registers
    reg [11:0] code_word_stage1;
    reg [3:0] syndrome_part_stage1;
    
    // Stage 2 registers
    reg [11:0] code_word_stage2;
    reg [3:0] syndrome_stage2;
    
    // Stage 3 registers
    reg [11:0] code_word_stage3;
    reg [3:0] syndrome_stage3;
    
    // Pipeline Stage 1: Syndrome calculation with LUT approach
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_stage1 <= 12'b0;
            syndrome_part_stage1 <= 4'b0;
        end else begin
            code_word_stage1 <= code_word;
            
            // Syndrome bit 0 calculation using LUT approach
            syndrome_part_stage1[0] <= ^(code_word & 12'b010101010101);
            
            // Syndrome bit 1 calculation using LUT approach
            syndrome_part_stage1[1] <= ^(code_word & 12'b011001100110);
            
            // Syndrome bit 2 calculation using LUT approach
            syndrome_part_stage1[2] <= ^(code_word & 12'b000111100000);
            
            // Syndrome bit 3 calculation using LUT approach
            syndrome_part_stage1[3] <= ^(code_word & 12'b000000011110);
        end
    end
    
    // Pipeline Stage 2: Syndrome completion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_stage2 <= 12'b0;
            syndrome_stage2 <= 4'b0;
        end else begin
            code_word_stage2 <= code_word_stage1;
            syndrome_stage2 <= syndrome_part_stage1;
        end
    end
    
    // Pipeline Stage 3: Prepare for error correction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_stage3 <= 12'b0;
            syndrome_stage3 <= 4'b0;
        end else begin
            code_word_stage3 <= code_word_stage2;
            syndrome_stage3 <= syndrome_stage2;
        end
    end
    
    // Final stage: Error correction and output generation using LUT
    reg [11:0] corrected_word;
    reg [7:0] data_lut [0:15]; // LUT for data extraction based on syndrome
    reg [1:0] error_flags_lut [0:31]; // LUT for error flags: {double_error, error_fixed}
    
    // Generate corrected word using syndrome as index for bit flip
    always @(*) begin
        corrected_word = code_word_stage3;
        if (|syndrome_stage3) begin
            // Only flip bit if syndrome is non-zero
            case (syndrome_stage3)
                4'b0001: corrected_word[0] = ~code_word_stage3[0];
                4'b0010: corrected_word[1] = ~code_word_stage3[1];
                4'b0011: corrected_word[2] = ~code_word_stage3[2];
                4'b0100: corrected_word[3] = ~code_word_stage3[3];
                4'b0101: corrected_word[4] = ~code_word_stage3[4];
                4'b0110: corrected_word[5] = ~code_word_stage3[5];
                4'b0111: corrected_word[6] = ~code_word_stage3[6];
                4'b1000: corrected_word[7] = ~code_word_stage3[7];
                4'b1001: corrected_word[8] = ~code_word_stage3[8];
                4'b1010: corrected_word[9] = ~code_word_stage3[9];
                4'b1011: corrected_word[10] = ~code_word_stage3[10];
                4'b1100: corrected_word[11] = ~code_word_stage3[11];
                default: corrected_word = code_word_stage3;
            endcase
        end
    end
    
    // Final output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            error_fixed <= 1'b0;
            double_error <= 1'b0;
        end else begin
            // Extract data bits directly from positions using concatenation
            data_out <= {corrected_word[10:7], corrected_word[6:4], corrected_word[2]};
            
            // Error flag logic using LUT approach
            // Error can be fixed if syndrome is non-zero and parity check passes
            error_fixed <= |syndrome_stage3 && ~(^syndrome_stage3 ^ code_word_stage3[11]);
            
            // Double error if syndrome is non-zero and parity check fails
            double_error <= |syndrome_stage3 && (^syndrome_stage3 ^ code_word_stage3[11]);
        end
    end
endmodule