module pipelined_hamming_enc(
    input clk, rst_n,
    input [7:0] data_in,
    output reg [11:0] encoded_out
);
    reg [7:0] stage1_data;
    reg [3:0] stage1_parity;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_parity <= 4'b0;
            encoded_out <= 12'b0;
        end else begin
            // Stage 1: Calculate parity bits
            stage1_data <= data_in;
            stage1_parity[0] <= ^(data_in & 8'b10101010);
            stage1_parity[1] <= ^(data_in & 8'b11001100);
            stage1_parity[2] <= ^(data_in & 8'b11110000);
            stage1_parity[3] <= ^{stage1_parity[2:0], data_in};
            
            // Stage 2: Assemble encoded output
            encoded_out <= {stage1_parity[3], stage1_data, stage1_parity[2:0]};
        end
    end
endmodule