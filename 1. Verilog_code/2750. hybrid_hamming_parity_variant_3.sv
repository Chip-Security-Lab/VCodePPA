//SystemVerilog
module hybrid_hamming_parity(
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] encoded
);
    reg [6:0] hamming_code;
    reg [3:0] parity_bits;
    
    // Hamming code calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hamming_code <= 7'b0;
        end else begin
            hamming_code[0] <= data[0] ^ data[1] ^ data[3];
            hamming_code[1] <= data[0] ^ data[2] ^ data[3];
            hamming_code[2] <= data[0];
            hamming_code[3] <= data[1] ^ data[2] ^ data[3];
            hamming_code[4] <= data[1];
            hamming_code[5] <= data[2];
            hamming_code[6] <= data[3];
        end
    end
    
    // Parity bits calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_bits <= 4'b0;
        end else begin
            parity_bits[0] <= data[4] ^ data[5] ^ data[6] ^ data[7];
            parity_bits[1] <= data[6] ^ data[7];
            parity_bits[2] <= data[4] ^ data[5];
            parity_bits[3] <= data[4] ^ data[5] ^ data[6] ^ data[7];
        end
    end
    
    // Final encoded output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded <= 16'b0;
        end else begin
            encoded <= {data[7:4], parity_bits, hamming_code};
        end
    end
endmodule