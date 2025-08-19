//SystemVerilog
module hamming_decoder_4b(
    input clock, reset,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected
);
    // Stage 1 registers
    reg [6:0] code_in_stage1;
    reg [2:0] syndrome_stage1;
    
    // Stage 2 registers
    reg [6:0] code_in_stage2;
    reg [2:0] syndrome_stage2;
    reg error_detected_stage2;
    
    // Stage 1: Syndrome calculation
    always @(posedge clock) begin
        if (reset) begin
            code_in_stage1 <= 7'b0;
            syndrome_stage1 <= 3'b0;
        end else begin
            code_in_stage1 <= code_in;
            syndrome_stage1[0] <= code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
            syndrome_stage1[1] <= code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
            syndrome_stage1[2] <= code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
        end
    end

    // Stage 2: Error detection and data extraction
    always @(posedge clock) begin
        if (reset) begin
            code_in_stage2 <= 7'b0;
            syndrome_stage2 <= 3'b0;
            error_detected_stage2 <= 1'b0;
        end else begin
            code_in_stage2 <= code_in_stage1;
            syndrome_stage2 <= syndrome_stage1;
            error_detected_stage2 <= |syndrome_stage1;
        end
    end

    // Stage 3: Final output
    always @(posedge clock) begin
        if (reset) begin
            data_out <= 4'b0;
            error_detected <= 1'b0;
        end else begin
            data_out <= {code_in_stage2[6], code_in_stage2[5], code_in_stage2[4], code_in_stage2[2]};
            error_detected <= error_detected_stage2;
        end
    end
endmodule