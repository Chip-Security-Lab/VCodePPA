//SystemVerilog
module hybrid_hamming_parity(
    input clk, rst_n,
    input [7:0] data,
    input valid,        // Input valid signal (sender has valid data)
    output ready,       // Output ready signal (receiver is ready)
    output reg [15:0] encoded,
    output reg encoded_valid  // Output valid signal (indicates encoded data is valid)
);
    reg [11:0] hamming_code;
    reg [3:0] parity_bits;
    reg processing;
    
    // Ready when not processing or when both processing and encoded_valid
    assign ready = !processing || encoded_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            encoded_valid <= 1'b0;
            encoded <= 16'b0;
            hamming_code <= 12'b0;
            parity_bits <= 4'b0;
        end else begin
            // Start processing when valid data arrives and we're ready
            if (valid && ready) begin
                processing <= 1'b1;
                encoded_valid <= 1'b0;
                
                // Calculate hamming code
                hamming_code[0] <= data[0] ^ data[1] ^ data[3];
                hamming_code[1] <= data[0] ^ data[2] ^ data[3];
                hamming_code[2] <= data[0];
                hamming_code[3] <= data[1] ^ data[2] ^ data[3];
                hamming_code[4] <= data[1];
                hamming_code[5] <= data[2];
                hamming_code[6] <= data[3];
                
                // Calculate parity bits
                parity_bits[0] <= ^data[7:4];
                parity_bits[1] <= ^{data[7], data[6]};
                parity_bits[2] <= ^{data[5], data[4]};
                parity_bits[3] <= ^data[7:4];
            end
            
            // Complete processing in the next cycle
            if (processing && !encoded_valid) begin
                encoded <= {data[7:4], parity_bits, hamming_code[6:0]};
                encoded_valid <= 1'b1;
                processing <= 1'b0;
            end
            
            // Clear valid when downstream is ready
            if (encoded_valid && ready) begin
                encoded_valid <= 1'b0;
            end
        end
    end
endmodule