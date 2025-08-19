//SystemVerilog
module pipelined_hamming_enc(
    input clk, rst_n,
    input [7:0] data_in,
    output reg [11:0] encoded_out
);
    // Stage 1: Input register and first part of parity calculation
    reg [7:0] stage1_data;
    reg [2:0] stage1_parity_partial;
    
    // Stage 2: Intermediate parity calculation
    reg [7:0] stage2_data;
    reg [2:0] stage2_parity;
    
    // Stage 3: Final parity calculation
    reg [7:0] stage3_data;
    reg [2:0] stage3_parity;
    reg stage3_parity3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            stage1_data <= 8'b0;
            stage1_parity_partial <= 3'b0;
            
            stage2_data <= 8'b0;
            stage2_parity <= 3'b0;
            
            stage3_data <= 8'b0;
            stage3_parity <= 3'b0;
            stage3_parity3 <= 1'b0;
            
            encoded_out <= 12'b0;
        end else begin
            // Stage 1: Register input and calculate partial parity bits
            stage1_data <= data_in;
            stage1_parity_partial[0] <= ^(data_in & 8'b10101010);
            stage1_parity_partial[1] <= ^(data_in & 8'b11001100);
            stage1_parity_partial[2] <= ^(data_in & 8'b11110000);
            
            // Stage 2: Pass data and partial parity bits
            stage2_data <= stage1_data;
            stage2_parity <= stage1_parity_partial;
            
            // Stage 3: Calculate final parity bit and prepare for output
            stage3_data <= stage2_data;
            stage3_parity <= stage2_parity;
            stage3_parity3 <= ^{stage2_parity, stage2_data};
            
            // Stage 4: Assemble final encoded output
            encoded_out <= {stage3_parity3, stage3_data, stage3_parity};
        end
    end
endmodule