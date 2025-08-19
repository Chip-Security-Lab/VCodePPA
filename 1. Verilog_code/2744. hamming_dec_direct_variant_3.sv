//SystemVerilog
module hamming_dec_direct(
    input [6:0] code_in,
    output [3:0] data_out,
    output error
);
    wire [2:0] syndrome;
    wire [6:0] corrected;
    
    // Optimized syndrome calculation using XOR reduction
    assign syndrome[0] = ^{code_in[0], code_in[2], code_in[4], code_in[6]};
    assign syndrome[1] = ^{code_in[1], code_in[2], code_in[5], code_in[6]};
    assign syndrome[2] = ^{code_in[3], code_in[4], code_in[5], code_in[6]};
    
    // Simplified correction logic using conditional assignments
    // Single bit flips based on syndrome value
    assign corrected = (syndrome == 3'b000) ? code_in :                    // No error
                       {(syndrome == 3'b111) ? ~code_in[6] : code_in[6],   // Bit 6 error
                        (syndrome == 3'b110) ? ~code_in[5] : code_in[5],   // Bit 5 error
                        (syndrome == 3'b101) ? ~code_in[4] : code_in[4],   // Bit 4 error
                        (syndrome == 3'b100) ? ~code_in[3] : code_in[3],   // Bit 3 error
                        (syndrome == 3'b011) ? ~code_in[2] : code_in[2],   // Bit 2 error
                        (syndrome == 3'b010) ? ~code_in[1] : code_in[1],   // Bit 1 error
                        (syndrome == 3'b001) ? ~code_in[0] : code_in[0]};  // Bit 0 error
    
    // Extract data bits directly without using corrected signal intermediary
    assign data_out = {
        (syndrome == 3'b111) ? ~code_in[6] : code_in[6],
        (syndrome == 3'b110) ? ~code_in[5] : code_in[5], 
        (syndrome == 3'b101) ? ~code_in[4] : code_in[4],
        (syndrome == 3'b011) ? ~code_in[2] : code_in[2]
    };
    
    // Simplified error detection
    assign error = |syndrome;
endmodule