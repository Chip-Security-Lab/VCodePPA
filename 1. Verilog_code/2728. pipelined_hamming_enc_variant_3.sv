//SystemVerilog
module pipelined_hamming_enc(
    input clk, rst_n,
    input [7:0] data_in,
    output reg [11:0] encoded_out
);
    // Stage 1: Input registration and partial parity calculation
    reg [7:0] stage1_data;
    reg [2:0] stage1_parity_partial;
    
    // Stage 2: Complete parity calculation
    reg [7:0] stage2_data;
    reg [2:0] stage2_parity;
    
    // Stage 3: Final parity calculation
    reg [7:0] stage3_data;
    reg [2:0] stage3_parity;
    reg stage3_final_parity;
    
    // Stage 1: Register input and calculate partial parity bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_parity_partial <= 3'b0;
        end else begin
            stage1_data <= data_in;
            stage1_parity_partial[0] <= ^(data_in & 8'b10101010);
            stage1_parity_partial[1] <= ^(data_in & 8'b11001100);
            stage1_parity_partial[2] <= ^(data_in & 8'b11110000);
        end
    end
    
    // Stage 2: Pass data and complete basic parity calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 8'b0;
            stage2_parity <= 3'b0;
        end else begin
            stage2_data <= stage1_data;
            stage2_parity <= stage1_parity_partial;
        end
    end
    
    // Stage 3: Calculate final parity and prepare for output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= 8'b0;
            stage3_parity <= 3'b0;
            stage3_final_parity <= 1'b0;
        end else begin
            stage3_data <= stage2_data;
            stage3_parity <= stage2_parity;
            stage3_final_parity <= ^{stage2_parity, stage2_data};
        end
    end
    
    // Stage 4: Assemble the final encoded output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 12'b0;
        end else begin
            encoded_out <= {stage3_final_parity, stage3_data, stage3_parity};
        end
    end
endmodule