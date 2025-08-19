//SystemVerilog
module pipelined_hamming_enc(
    input clk, rst_n,
    input [7:0] data_in,
    output reg [11:0] encoded_out
);
    reg [7:0] stage1_data;
    reg [2:0] stage1_parity;
    reg [7:0] stage1_data_masked[2:0];
    reg [3:0] stage1_xor_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_parity <= 3'b0;
            stage1_data_masked[0] <= 8'b0;
            stage1_data_masked[1] <= 8'b0;
            stage1_data_masked[2] <= 8'b0;
            stage1_xor_result <= 4'b0;
            encoded_out <= 12'b0;
        end else begin
            // Stage 1: Calculate parity bits - masks applied in parallel
            stage1_data <= data_in;
            
            // Apply masks in parallel to reduce logic depth
            stage1_data_masked[0] <= data_in & 8'b10101010;
            stage1_data_masked[1] <= data_in & 8'b11001100;
            stage1_data_masked[2] <= data_in & 8'b11110000;
            
            // Calculate parity bits (XOR operations)
            stage1_parity[0] <= ^(stage1_data_masked[0]);
            stage1_parity[1] <= ^(stage1_data_masked[1]);
            stage1_parity[2] <= ^(stage1_data_masked[2]);
            
            // Calculate overall parity using pre-computed values instead of raw data
            stage1_xor_result <= {1'b0, stage1_parity} ^ {1'b0, ^data_in[7:6], ^data_in[5:4], ^data_in[3:0]};
            
            // Stage 2: Assemble encoded output with balanced parity calculation
            encoded_out <= {stage1_xor_result[0], stage1_data, stage1_parity};
        end
    end
endmodule