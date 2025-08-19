//SystemVerilog
module pipelined_hamming_enc(
    input clk, rst_n,
    input [7:0] data_in,
    output reg [11:0] encoded_out
);
    reg [7:0] stage1_data;
    reg [2:0] stage1_parity;
    wire [2:0] parity_bits;
    
    // Pre-compute parity bits combinationally
    assign parity_bits[0] = data_in[7] ^ data_in[5] ^ data_in[3] ^ data_in[1];
    assign parity_bits[1] = data_in[6] ^ data_in[5] ^ data_in[2] ^ data_in[1];
    assign parity_bits[2] = data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_parity <= 3'b0;
            encoded_out <= 12'b0;
        end else begin
            // Stage 1: Register data and pre-calculated parity bits
            stage1_data <= data_in;
            stage1_parity <= parity_bits;
            
            // Stage 2: Assemble encoded output with overall parity
            encoded_out[11] <= ^{stage1_parity, stage1_data};
            encoded_out[10:3] <= stage1_data;
            encoded_out[2:0] <= stage1_parity;
        end
    end
endmodule