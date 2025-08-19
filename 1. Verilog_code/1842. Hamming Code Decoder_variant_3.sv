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
    
    // Calculate syndrome using Wallace tree structure
    wire s0_1 = p1 ^ d1;
    wire s0_2 = d2 ^ d4;
    wire s0_3 = p2 ^ d1;
    wire s0_4 = d3 ^ d4;
    wire s0_5 = p4 ^ d2;
    wire s0_6 = d3 ^ d4;
    
    wire s1_1 = s0_1 ^ s0_2;
    wire s1_2 = s0_3 ^ s0_4;
    wire s1_3 = s0_5 ^ s0_6;
    
    assign syndrome[0] = s1_1;
    assign syndrome[1] = s1_2;
    assign syndrome[2] = s1_3;
    
    // Error detection and correction
    assign error_detected = |syndrome;
    assign error_corrected = error_detected;
    
    // Error correction using Wallace tree structure
    wire [6:0] flip_mask;
    wire [6:0] correction_result;
    
    // Generate flip mask using Wallace tree
    wire [2:0] syndrome_n = ~syndrome;
    wire [6:0] syndrome_expanded = {syndrome_n[2], syndrome_n[1], syndrome_n[0], 
                                   syndrome_n[2], syndrome_n[1], syndrome_n[0], 
                                   syndrome_n[2]};
    
    assign flip_mask = syndrome_expanded & 7'b0000001;
    
    // Apply correction
    assign correction_result = encoded_in ^ flip_mask;
    
    always @(*) begin
        corrected_code = correction_result;
        decoded_out[0] = corrected_code[2];
        decoded_out[1] = corrected_code[4];
        decoded_out[2] = corrected_code[5];
        decoded_out[3] = corrected_code[6];
    end
endmodule