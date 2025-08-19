//SystemVerilog
module hamming_dec_direct(
    input [6:0] code_in,
    output [3:0] data_out,
    output error
);
    wire [2:0] syndrome;
    wire [6:0] corrected;
    reg [6:0] correction_mask;
    
    // Calculate syndrome
    assign syndrome[0] = code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
    assign syndrome[1] = code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
    assign syndrome[2] = code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
    
    // Generate correction mask using if-else structure
    always @(*) begin
        if (syndrome == 3'b000) begin
            correction_mask = 7'b0000000;
        end
        else if (syndrome == 3'b001) begin
            correction_mask = 7'b0000001;
        end
        else if (syndrome == 3'b010) begin
            correction_mask = 7'b0000010;
        end
        else if (syndrome == 3'b011) begin
            correction_mask = 7'b0000100;
        end
        else if (syndrome == 3'b100) begin
            correction_mask = 7'b0001000;
        end
        else if (syndrome == 3'b101) begin
            correction_mask = 7'b0010000;
        end
        else if (syndrome == 3'b110) begin
            correction_mask = 7'b0100000;
        end
        else begin
            correction_mask = 7'b1000000;
        end
    end
    
    // Apply correction using XOR
    assign corrected = code_in ^ correction_mask;
    
    // Extract data bits
    assign data_out = {corrected[6], corrected[5], corrected[4], corrected[2]};
    assign error = |syndrome;
endmodule