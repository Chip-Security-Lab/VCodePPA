module hamming_dec_direct(
    input [6:0] code_in,
    output [3:0] data_out,
    output error
);
    wire [2:0] syndrome;
    wire [6:0] corrected;
    
    // Calculate syndrome
    assign syndrome[0] = code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
    assign syndrome[1] = code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
    assign syndrome[2] = code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
    
    // Apply correction directly based on syndrome
    assign corrected = (syndrome == 3'b000) ? code_in :
                      (syndrome == 3'b001) ? code_in ^ 7'b0000001 :
                      (syndrome == 3'b010) ? code_in ^ 7'b0000010 :
                      (syndrome == 3'b011) ? code_in ^ 7'b0000100 :
                      (syndrome == 3'b100) ? code_in ^ 7'b0001000 :
                      (syndrome == 3'b101) ? code_in ^ 7'b0010000 :
                      (syndrome == 3'b110) ? code_in ^ 7'b0100000 :
                                           code_in ^ 7'b1000000;
    
    // Extract data bits
    assign data_out = {corrected[6], corrected[5], corrected[4], corrected[2]};
    assign error = |syndrome;
endmodule