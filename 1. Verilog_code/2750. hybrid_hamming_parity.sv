module hybrid_hamming_parity(
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] encoded
);
    reg [11:0] hamming_code;
    reg [3:0] parity_bits;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hamming_code <= 12'b0;
            parity_bits <= 4'b0;
            encoded <= 16'b0;
        end else begin
            // Hamming code for first 4 bits
            hamming_code[0] <= data[0] ^ data[1] ^ data[3];
            hamming_code[1] <= data[0] ^ data[2] ^ data[3];
            hamming_code[2] <= data[0];
            hamming_code[3] <= data[1] ^ data[2] ^ data[3];
            hamming_code[4] <= data[1];
            hamming_code[5] <= data[2];
            hamming_code[6] <= data[3];
            
            // Simple parity for remaining 4 bits
            parity_bits[0] <= ^data[7:4];
            parity_bits[1] <= ^{data[7], data[6]};
            parity_bits[2] <= ^{data[5], data[4]};
            parity_bits[3] <= ^data[7:4];
            
            // Combine both codes
            encoded <= {data[7:4], parity_bits, hamming_code[6:0]};
        end
    end
endmodule