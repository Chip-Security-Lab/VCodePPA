//SystemVerilog
module ecc_signal_recovery (
    input wire clock,
    input wire reset,
    input wire [6:0] encoded_data,
    input wire valid_in,
    output wire ready_in,
    output reg [3:0] corrected_data,
    output reg error_detected,
    output reg valid_out,
    input wire ready_out
);
    // Stage 1: Extract bits and compute syndrome
    reg [6:0] encoded_data_stage1;
    reg valid_stage1;
    wire [2:0] syndrome_stage1;
    
    wire p1 = encoded_data_stage1[0];
    wire p2 = encoded_data_stage1[1];
    wire d1 = encoded_data_stage1[2];
    wire p3 = encoded_data_stage1[3];
    wire d2 = encoded_data_stage1[4];
    wire d3 = encoded_data_stage1[5];
    wire d4 = encoded_data_stage1[6];
    
    assign syndrome_stage1[0] = p1 ^ d1 ^ d2 ^ d4;
    assign syndrome_stage1[1] = p2 ^ d1 ^ d3 ^ d4;
    assign syndrome_stage1[2] = p3 ^ d2 ^ d3 ^ d4;
    
    // Stage 2: Correction based on syndrome
    reg [6:0] encoded_data_stage2;
    reg [2:0] syndrome_stage2;
    reg valid_stage2;
    
    // Optimized handshaking control
    wire stage1_advance = !valid_stage1 || ready_out;
    wire stage2_advance = !valid_stage2 || ready_out;
    assign ready_in = !valid_stage1 || (valid_stage2 && ready_out);
    
    // Stage 1 pipeline registers
    always @(posedge clock) begin
        if (reset) begin
            encoded_data_stage1 <= 7'b0;
            valid_stage1 <= 1'b0;
        end else if (stage1_advance) begin
            encoded_data_stage1 <= valid_in && ready_in ? encoded_data : 7'b0;
            valid_stage1 <= valid_in && ready_in;
        end
    end
    
    // Stage 2 pipeline registers
    always @(posedge clock) begin
        if (reset) begin
            encoded_data_stage2 <= 7'b0;
            syndrome_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end else if (stage2_advance) begin
            encoded_data_stage2 <= valid_stage1 ? encoded_data_stage1 : 7'b0;
            syndrome_stage2 <= valid_stage1 ? syndrome_stage1 : 3'b0;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Optimized output stage with parallel syndrome decoding
    wire [3:0] syndrome_match = {
        syndrome_stage2 == 3'b111,  // d4 error
        syndrome_stage2 == 3'b110,  // d3 error
        syndrome_stage2 == 3'b101,  // d2 error
        syndrome_stage2 == 3'b011   // d1 error
    };
    
    always @(posedge clock) begin
        if (reset) begin
            corrected_data <= 4'b0;
            error_detected <= 1'b0;
            valid_out <= 1'b0;
        end else if (ready_out) begin
            if (valid_stage2) begin
                error_detected <= |syndrome_stage2;
                
                // Parallel error correction using syndrome_match
                corrected_data <= {
                    syndrome_match[3] ? ~encoded_data_stage2[6] : encoded_data_stage2[6],
                    syndrome_match[2] ? ~encoded_data_stage2[5] : encoded_data_stage2[5],
                    syndrome_match[1] ? ~encoded_data_stage2[4] : encoded_data_stage2[4],
                    syndrome_match[0] ? ~encoded_data_stage2[2] : encoded_data_stage2[2]
                };
                
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule