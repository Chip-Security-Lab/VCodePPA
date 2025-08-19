//SystemVerilog
module hamming_decoder_4b(
    input clock, reset,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected
);

    // Stage 1 registers - Input buffering
    reg [6:0] code_in_stage1;
    
    // Stage 2 registers - Syndrome calculation part 1
    reg [6:0] code_in_stage2;
    reg [1:0] syndrome_part1_stage2;
    
    // Stage 3 registers - Syndrome calculation part 2
    reg [6:0] code_in_stage3;
    reg [1:0] syndrome_part1_stage3;
    reg syndrome_part2_stage3;
    
    // Stage 4 registers - Syndrome combination
    reg [6:0] code_in_stage4;
    reg [2:0] syndrome_stage4;
    
    // Stage 5 registers - Error detection and data extraction
    reg [3:0] data_stage5;
    reg error_stage5;

    // Stage 1: Input buffering
    always @(posedge clock) begin
        if (reset) begin
            code_in_stage1 <= 7'b0;
        end else begin
            code_in_stage1 <= code_in;
        end
    end

    // Stage 2: Syndrome calculation part 1
    always @(posedge clock) begin
        if (reset) begin
            code_in_stage2 <= 7'b0;
            syndrome_part1_stage2 <= 2'b0;
        end else begin
            code_in_stage2 <= code_in_stage1;
            syndrome_part1_stage2[0] <= code_in_stage1[0] ^ code_in_stage1[2] ^ code_in_stage1[4];
            syndrome_part1_stage2[1] <= code_in_stage1[1] ^ code_in_stage1[2] ^ code_in_stage1[5];
        end
    end

    // Stage 3: Syndrome calculation part 2
    always @(posedge clock) begin
        if (reset) begin
            code_in_stage3 <= 7'b0;
            syndrome_part1_stage3 <= 2'b0;
            syndrome_part2_stage3 <= 1'b0;
        end else begin
            code_in_stage3 <= code_in_stage2;
            syndrome_part1_stage3 <= syndrome_part1_stage2;
            syndrome_part2_stage3 <= code_in_stage2[3] ^ code_in_stage2[4] ^ code_in_stage2[5];
        end
    end

    // Stage 4: Syndrome combination
    always @(posedge clock) begin
        if (reset) begin
            code_in_stage4 <= 7'b0;
            syndrome_stage4 <= 3'b0;
        end else begin
            code_in_stage4 <= code_in_stage3;
            syndrome_stage4[1:0] <= syndrome_part1_stage3;
            syndrome_stage4[2] <= syndrome_part2_stage3;
        end
    end

    // Stage 5: Error detection and data extraction
    always @(posedge clock) begin
        if (reset) begin
            data_stage5 <= 4'b0;
            error_stage5 <= 1'b0;
        end else begin
            data_stage5 <= {code_in_stage4[6], code_in_stage4[5], code_in_stage4[4], code_in_stage4[2]};
            error_stage5 <= |syndrome_stage4;
        end
    end

    // Output stage
    always @(posedge clock) begin
        if (reset) begin
            data_out <= 4'b0;
            error_detected <= 1'b0;
        end else begin
            data_out <= data_stage5;
            error_detected <= error_stage5;
        end
    end

endmodule