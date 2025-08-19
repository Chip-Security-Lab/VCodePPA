module hamming_decoder (
    input wire [6:0] hamming_in,
    output reg [3:0] data_out,
    output reg error_detected
);
    reg [2:0] syndrome;
    
    always @(*) begin
        syndrome[0] = hamming_in[0] ^ hamming_in[2] ^ hamming_in[4] ^ hamming_in[6];
        syndrome[1] = hamming_in[1] ^ hamming_in[2] ^ hamming_in[5] ^ hamming_in[6];
        syndrome[2] = hamming_in[3] ^ hamming_in[4] ^ hamming_in[5] ^ hamming_in[6];
        
        error_detected = |syndrome;
        data_out = {hamming_in[6], hamming_in[5], hamming_in[4], hamming_in[2]};
    end
endmodule