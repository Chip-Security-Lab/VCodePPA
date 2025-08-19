//SystemVerilog
module hamming_recovery (
    input wire clk,
    input wire [11:0] encoded,
    output reg [7:0] decoded,
    output reg error_detected,
    output reg error_corrected
);
    // Stage 1 registers - syndrome calculation
    reg [3:0] syndrome;
    reg [11:0] encoded_r;
    
    // Stage 2 registers - error correction
    reg [11:0] corrected;
    reg error_detected_r;
    reg [3:0] syndrome_r;
    
    // Conditional sum subtractor signals
    wire [11:0] inverted_syndrome;
    wire [12:0] subtraction_result;
    wire [11:0] corrected_syndrome;
    wire valid_position;
    
    // Pipeline Stage 1: Calculate syndrome
    always @(posedge clk) begin
        // Calculate syndrome (split complex XOR operations)
        syndrome[0] = encoded[0] ^ encoded[2] ^ encoded[4] ^ encoded[6] ^ encoded[8] ^ encoded[10];
        syndrome[1] = encoded[1] ^ encoded[2] ^ encoded[5] ^ encoded[6] ^ encoded[9] ^ encoded[10];
        syndrome[2] = encoded[3] ^ encoded[4] ^ encoded[5] ^ encoded[6] ^ encoded[11];
        syndrome[3] = encoded[7] ^ encoded[8] ^ encoded[9] ^ encoded[10] ^ encoded[11];
        
        // Register encoded data for next stage
        encoded_r <= encoded;
        error_detected <= (syndrome != 4'b0000);
        syndrome_r <= syndrome;
    end
    
    // Conditional sum subtractor implementation
    assign inverted_syndrome = ~{8'b0, syndrome_r};
    assign subtraction_result = {1'b0, 12'd12} + {1'b0, inverted_syndrome} + 13'b1;
    assign valid_position = ~subtraction_result[12] & (subtraction_result[11:0] <= 12'd12);
    assign corrected_syndrome = (valid_position) ? syndrome_r : 12'd0;
    
    // Pipeline Stage 2: Error correction
    always @(posedge clk) begin
        error_detected_r <= error_detected;
        
        if (error_detected) begin
            // Use conditional sum subtractor result for correction logic
            if (valid_position) begin
                corrected <= encoded_r;
                corrected[corrected_syndrome-1] <= ~encoded_r[corrected_syndrome-1];
                error_corrected <= 1'b1;
            end else begin
                corrected <= encoded_r;
                error_corrected <= 1'b0;
            end
        end else begin
            corrected <= encoded_r;
            error_corrected <= 1'b0;
        end
    end
    
    // Pipeline Stage 3: Data extraction
    always @(posedge clk) begin
        // Extract data bits
        decoded <= {corrected[11], corrected[10], corrected[9], corrected[8], 
                   corrected[6], corrected[5], corrected[4], corrected[2]};
    end
endmodule