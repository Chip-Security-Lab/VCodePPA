//SystemVerilog
module hamming_decoder_4b(
    input clock, reset,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected,
    input valid_in,
    output reg valid_out,
    input flush
);

    // Stage 1 registers
    reg [6:0] code_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [2:0] syndrome_stage2;
    reg [3:0] data_stage2;
    reg valid_stage2;
    
    // Intermediate signals for syndrome calculation
    wire syndrome_bit0, syndrome_bit1, syndrome_bit2;
    
    // Syndrome calculation logic
    assign syndrome_bit0 = code_stage1[0] ^ code_stage1[2] ^ code_stage1[4] ^ code_stage1[6];
    assign syndrome_bit1 = code_stage1[1] ^ code_stage1[2] ^ code_stage1[5] ^ code_stage1[6];
    assign syndrome_bit2 = code_stage1[3] ^ code_stage1[4] ^ code_stage1[5] ^ code_stage1[6];
    
    // Pipeline stage 1: Input capture
    always @(posedge clock) begin
        if (reset || flush) begin
            code_stage1 <= 7'b0;
            valid_stage1 <= 1'b0;
        end else if (valid_in) begin
            code_stage1 <= code_in;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Pipeline stage 2: Syndrome and data processing
    always @(posedge clock) begin
        if (reset || flush) begin
            syndrome_stage2 <= 3'b0;
            data_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            syndrome_stage2 <= {syndrome_bit2, syndrome_bit1, syndrome_bit0};
            data_stage2 <= {code_stage1[6], code_stage1[5], code_stage1[4], code_stage1[2]};
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Pipeline stage 3: Error detection and output
    always @(posedge clock) begin
        if (reset || flush) begin
            data_out <= 4'b0;
            error_detected <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_stage2) begin
            data_out <= data_stage2;
            error_detected <= |syndrome_stage2;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule