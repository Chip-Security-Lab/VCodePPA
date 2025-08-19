//SystemVerilog
module hamming_recovery (
    input wire clk,
    input wire [11:0] encoded,
    output reg [7:0] decoded,
    output reg error_detected,
    output reg error_corrected
);
    // Internal signals with pipeline stages to balance paths
    // Stage 1: Input buffering and parallel syndrome calculation
    reg [11:0] encoded_r;
    reg [3:0] syndrome_parts1, syndrome_parts2;
    
    // Stage 2: Syndrome completion and error detection
    reg [3:0] syndrome;
    reg syndrome_valid;
    reg [11:0] encoded_r2;
    
    // Stage 3: Error correction
    reg [11:0] corrected;
    reg error_corrected_internal;
    
    // Stage 4: Output mapping
    reg [11:0] corrected_r;
    
    // Distribute parity calculations across multiple stages to reduce timing paths
    always @(posedge clk) begin
        // Stage 1: Buffer input and start syndrome calculation in parallel paths
        encoded_r <= encoded;
        
        // Split parity calculations into smaller parallel groups
        syndrome_parts1[0] <= encoded[0] ^ encoded[2] ^ encoded[4];
        syndrome_parts1[1] <= encoded[6] ^ encoded[8] ^ encoded[10];
        syndrome_parts1[2] <= encoded[1] ^ encoded[2] ^ encoded[5];
        syndrome_parts1[3] <= encoded[6] ^ encoded[9] ^ encoded[10];
        
        syndrome_parts2[0] <= encoded[3] ^ encoded[4] ^ encoded[5];
        syndrome_parts2[1] <= encoded[6] ^ encoded[11];
        syndrome_parts2[2] <= encoded[7] ^ encoded[8] ^ encoded[9];
        syndrome_parts2[3] <= encoded[10] ^ encoded[11];
    end
    
    always @(posedge clk) begin
        // Stage 2: Complete syndrome calculation and error detection
        syndrome[0] <= syndrome_parts1[0] ^ syndrome_parts1[1];
        syndrome[1] <= syndrome_parts1[2] ^ syndrome_parts1[3];
        syndrome[2] <= syndrome_parts2[0] ^ syndrome_parts2[1];
        syndrome[3] <= syndrome_parts2[2] ^ syndrome_parts2[3];
        
        encoded_r2 <= encoded_r;
        syndrome_valid <= 1'b1; // Syndrome is valid in this cycle
    end
    
    // Pre-compute error position validity checking - reduces critical path
    reg error_position_valid;
    reg [3:0] syndrome_r;
    
    always @(posedge clk) begin
        // Stage 3: Error correction logic
        syndrome_r <= syndrome;
        error_detected <= (syndrome != 4'b0000) & syndrome_valid;
        
        // Precompute position validity check - breaks up complex condition
        error_position_valid <= (syndrome <= 4'd12) & (syndrome != 4'b0000);
        
        // Perform error correction with simplified condition
        if (error_position_valid) begin
            case (syndrome)
                4'd1:  corrected <= {encoded_r2[11:1], ~encoded_r2[0]};
                4'd2:  corrected <= {encoded_r2[11:2], ~encoded_r2[1], encoded_r2[0]};
                4'd3:  corrected <= {encoded_r2[11:3], ~encoded_r2[2], encoded_r2[1:0]};
                4'd4:  corrected <= {encoded_r2[11:4], ~encoded_r2[3], encoded_r2[2:0]};
                4'd5:  corrected <= {encoded_r2[11:5], ~encoded_r2[4], encoded_r2[3:0]};
                4'd6:  corrected <= {encoded_r2[11:6], ~encoded_r2[5], encoded_r2[4:0]};
                4'd7:  corrected <= {encoded_r2[11:7], ~encoded_r2[6], encoded_r2[5:0]};
                4'd8:  corrected <= {encoded_r2[11:8], ~encoded_r2[7], encoded_r2[6:0]};
                4'd9:  corrected <= {encoded_r2[11:9], ~encoded_r2[8], encoded_r2[7:0]};
                4'd10: corrected <= {encoded_r2[11:10], ~encoded_r2[9], encoded_r2[8:0]};
                4'd11: corrected <= {encoded_r2[11], ~encoded_r2[10], encoded_r2[9:0]};
                4'd12: corrected <= {~encoded_r2[11], encoded_r2[10:0]};
                default: corrected <= encoded_r2;
            endcase
            error_corrected_internal <= 1'b1;
        end else begin
            corrected <= encoded_r2;
            error_corrected_internal <= 1'b0;
        end
    end
    
    always @(posedge clk) begin
        // Stage 4: Output formatting
        corrected_r <= corrected;
        error_corrected <= error_corrected_internal;
        
        // Direct bit selection for decoded output - reduced complexity
        decoded[7] <= corrected[11];
        decoded[6] <= corrected[10];
        decoded[5] <= corrected[9];
        decoded[4] <= corrected[8];
        decoded[3] <= corrected[6];
        decoded[2] <= corrected[5];
        decoded[1] <= corrected[4];
        decoded[0] <= corrected[2];
    end
endmodule