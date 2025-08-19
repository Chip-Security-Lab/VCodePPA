//SystemVerilog
module hamming_decoder (
    input  wire [6:0] encoded_in,
    output wire [3:0] decoded_out,
    output wire       error_detected,
    output wire       error_corrected
);
    wire [2:0] syndrome;
    wire [6:0] corrected_code;
    
    // Calculate syndrome directly from encoded_in bits
    // This reduces the number of intermediate wires
    assign syndrome[0] = encoded_in[0] ^ encoded_in[2] ^ encoded_in[4] ^ encoded_in[6];
    assign syndrome[1] = encoded_in[1] ^ encoded_in[2] ^ encoded_in[5] ^ encoded_in[6];
    assign syndrome[2] = encoded_in[3] ^ encoded_in[4] ^ encoded_in[5] ^ encoded_in[6];
    
    // Simplified error detection logic
    assign error_detected = |syndrome;
    assign error_corrected = error_detected;
    
    // Optimized correction logic using bit manipulation instead of cascaded conditional expressions
    // This reduces the logic depth and improves timing
    assign corrected_code = encoded_in ^ (1'b1 << (syndrome - 1'b1));
    
    // Direct assignment for decoded output (changed from always block to continuous assignment)
    // This eliminates the need for a combinational always block
    assign decoded_out = {corrected_code[6], corrected_code[5], corrected_code[4], corrected_code[2]};
    
endmodule