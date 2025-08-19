//SystemVerilog
module hamming_decoder (
    input  wire [6:0] encoded_in,
    output reg  [3:0] decoded_out,
    output wire       error_detected,
    output wire       error_corrected
);
    wire [2:0] syndrome;
    reg  [6:0] corrected_code;
    
    // Extract data and parity bits
    wire p1 = encoded_in[0];
    wire p2 = encoded_in[1];
    wire d1 = encoded_in[2];
    wire p4 = encoded_in[3];
    wire d2 = encoded_in[4];
    wire d3 = encoded_in[5];
    wire d4 = encoded_in[6];
    
    // Calculate syndrome
    assign syndrome[0] = p1 ^ d1 ^ d2 ^ d4;
    assign syndrome[1] = p2 ^ d1 ^ d3 ^ d4;
    assign syndrome[2] = p4 ^ d2 ^ d3 ^ d4;
    
    // Error detection and correction
    assign error_detected = |syndrome;
    assign error_corrected = error_detected;
    
    // Flip the bit indicated by syndrome using if-else structure
    always @(*) begin
        corrected_code = encoded_in; // Default case: no error
        
        if (syndrome == 3'd1) begin
            corrected_code[0] = ~encoded_in[0];
        end
        else if (syndrome == 3'd2) begin
            corrected_code[1] = ~encoded_in[1];
        end
        else if (syndrome == 3'd3) begin
            corrected_code[2] = ~encoded_in[2];
        end
        else if (syndrome == 3'd4) begin
            corrected_code[3] = ~encoded_in[3];
        end
        else if (syndrome == 3'd5) begin
            corrected_code[4] = ~encoded_in[4];
        end
        else if (syndrome == 3'd6) begin
            corrected_code[5] = ~encoded_in[5];
        end
        else if (syndrome == 3'd7) begin
            corrected_code[6] = ~encoded_in[6];
        end
    end
    
    // Extract corrected data
    always @(*) begin
        decoded_out[0] = corrected_code[2];
        decoded_out[1] = corrected_code[4];
        decoded_out[2] = corrected_code[5];
        decoded_out[3] = corrected_code[6];
    end
endmodule