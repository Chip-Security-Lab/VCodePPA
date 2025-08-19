//SystemVerilog
module hamming_dec_direct(
    input [6:0] code_in,
    output [3:0] data_out,
    output error
);
    wire [2:0] syndrome;
    wire [6:0] correction_mask;
    wire [6:0] corrected;
    
    // Calculate syndrome using parallel XOR
    assign syndrome[0] = ^code_in[6:0] & 7'b1010101;
    assign syndrome[1] = ^code_in[6:0] & 7'b1100110;
    assign syndrome[2] = ^code_in[6:0] & 7'b1111000;
    
    // Generate correction mask using decoder
    assign correction_mask = (syndrome == 3'b000) ? 7'b0000000 :
                           (syndrome == 3'b001) ? 7'b0000001 :
                           (syndrome == 3'b010) ? 7'b0000010 :
                           (syndrome == 3'b011) ? 7'b0000100 :
                           (syndrome == 3'b100) ? 7'b0001000 :
                           (syndrome == 3'b101) ? 7'b0010000 :
                           (syndrome == 3'b110) ? 7'b0100000 :
                           7'b1000000;
    
    // Apply correction in single step
    assign corrected = code_in ^ correction_mask;
    
    // Extract data bits using bit selection
    assign data_out = {corrected[6], corrected[5], corrected[4], corrected[2]};
    assign error = |syndrome;
endmodule