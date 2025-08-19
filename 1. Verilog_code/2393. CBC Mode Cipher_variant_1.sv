//SystemVerilog - IEEE 1364-2005
module cbc_mode_cipher #(parameter BLOCK_SIZE = 32) (
    input wire clk, rst,
    input wire enable, encrypt,
    input wire [BLOCK_SIZE-1:0] iv, data_in, key,
    output reg [BLOCK_SIZE-1:0] data_out,
    output reg valid_out
);
    // Pipeline stage registers - expanded from 3 to 5 stages
    reg [BLOCK_SIZE-1:0] data_stage1, data_stage2, data_stage3, data_stage4;
    reg [BLOCK_SIZE-1:0] prev_block;
    reg [BLOCK_SIZE-1:0] prev_block_stage1, prev_block_stage2, prev_block_stage3;
    reg [BLOCK_SIZE-1:0] key_stage1, key_stage2, key_stage3;
    reg encrypt_stage1, encrypt_stage2, encrypt_stage3, encrypt_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Stage 1: Input processing and initial XOR for encryption
    wire [BLOCK_SIZE-1:0] xor_result;
    assign xor_result = data_in ^ prev_block;
    
    // Stage 2: First part of cipher operation - key preparation
    wire [BLOCK_SIZE-1:0] key_modified_stage1;
    assign key_modified_stage1 = {key_stage1[7:0], key_stage1[31:8]};
    
    // Stage 3: Second part of cipher operation - partial computation
    wire [BLOCK_SIZE-1:0] cipher_in_stage2;
    wire [BLOCK_SIZE-1:0] partial_result_stage2;
    assign cipher_in_stage2 = encrypt_stage2 ? data_stage2 : data_stage2;
    assign partial_result_stage2 = cipher_in_stage2 ^ key_modified_stage1[31:16];
    
    // Stage 4: Third part of cipher operation - complete computation
    wire [BLOCK_SIZE-1:0] cipher_out_stage3;
    assign cipher_out_stage3 = data_stage3 ^ {key_stage2[15:0], 16'b0};
    
    // Stage 5: Output processing
    wire [BLOCK_SIZE-1:0] final_output;
    assign final_output = encrypt_stage4 ? data_stage4 : (data_stage4 ^ prev_block_stage3);
    
    // Pipeline control and data flow
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline registers
            prev_block <= iv;
            data_stage1 <= {BLOCK_SIZE{1'b0}};
            data_stage2 <= {BLOCK_SIZE{1'b0}};
            data_stage3 <= {BLOCK_SIZE{1'b0}};
            data_stage4 <= {BLOCK_SIZE{1'b0}};
            prev_block_stage1 <= {BLOCK_SIZE{1'b0}};
            prev_block_stage2 <= {BLOCK_SIZE{1'b0}};
            prev_block_stage3 <= {BLOCK_SIZE{1'b0}};
            key_stage1 <= {BLOCK_SIZE{1'b0}};
            key_stage2 <= {BLOCK_SIZE{1'b0}};
            key_stage3 <= {BLOCK_SIZE{1'b0}};
            encrypt_stage1 <= 0;
            encrypt_stage2 <= 0;
            encrypt_stage3 <= 0;
            encrypt_stage4 <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
            valid_stage4 <= 0;
            valid_out <= 0;
            data_out <= {BLOCK_SIZE{1'b0}};
        end 
        else begin
            // Stage 1 pipeline registers
            if (enable) begin
                data_stage1 <= encrypt ? xor_result : data_in;
                key_stage1 <= key;
                encrypt_stage1 <= encrypt;
                valid_stage1 <= 1;
                prev_block_stage1 <= prev_block;
            end 
            else begin
                valid_stage1 <= 0;
            end
            
            // Stage 2 pipeline registers
            data_stage2 <= data_stage1;
            key_stage2 <= key_stage1;
            encrypt_stage2 <= encrypt_stage1;
            valid_stage2 <= valid_stage1;
            prev_block_stage2 <= prev_block_stage1;
            
            // Stage 3 pipeline registers
            data_stage3 <= partial_result_stage2;
            key_stage3 <= key_stage2;
            encrypt_stage3 <= encrypt_stage2;
            valid_stage3 <= valid_stage2;
            prev_block_stage3 <= prev_block_stage2;
            
            // Stage 4 pipeline registers
            data_stage4 <= cipher_out_stage3;
            encrypt_stage4 <= encrypt_stage3;
            valid_stage4 <= valid_stage3;
            
            // Output stage
            data_out <= final_output;
            valid_out <= valid_stage4;
            
            // Update previous block for next input
            if (valid_stage4) begin
                if (encrypt_stage4) begin
                    prev_block <= data_stage4;  // For encryption, use cipher output
                end 
                else begin
                    prev_block <= data_in;      // For decryption, use input ciphertext
                end
            end
        end
    end
endmodule