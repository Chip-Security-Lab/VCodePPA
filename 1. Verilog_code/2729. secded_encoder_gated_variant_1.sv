//SystemVerilog
module secded_encoder_req_ack(
    input clk, rst,
    input req,
    input [3:0] data,
    output reg [7:0] code,
    output reg ack
);
    reg processing;
    reg [6:0] hamming_code;
    reg req_d;
    
    wire req_posedge = req & ~req_d;
    wire [2:0] parity_bits;
    wire overall_parity;
    
    // Precompute parity bits
    assign parity_bits[0] = ^data[1:0];
    assign parity_bits[1] = ^data[2:0];
    assign parity_bits[2] = ^data[3:1];
    
    // Precompute overall parity
    assign overall_parity = ^{parity_bits, data};
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_d <= 1'b0;
            processing <= 1'b0;
            ack <= 1'b0;
            hamming_code <= 7'b0;
            code <= 8'b0;
        end else begin
            req_d <= req;
            
            if (req_posedge && !processing) begin
                processing <= 1'b1;
                ack <= 1'b0;
                
                // Optimized Hamming code generation
                hamming_code[0] <= parity_bits[0] ^ data[3];
                hamming_code[1] <= parity_bits[1];
                hamming_code[2] <= data[0];
                hamming_code[3] <= parity_bits[2];
                hamming_code[4] <= data[1];
                hamming_code[5] <= data[2];
                hamming_code[6] <= data[3];
            end else if (processing) begin
                code <= {overall_parity, hamming_code};
                ack <= 1'b1;
                processing <= 1'b0;
            end else if (!req && ack) begin
                ack <= 1'b0;
            end
        end
    end
endmodule