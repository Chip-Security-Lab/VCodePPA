//SystemVerilog
module cbc_mode_cipher #(parameter BLOCK_SIZE = 32) (
    input wire clk, rst,
    input wire enable, encrypt,
    input wire [BLOCK_SIZE-1:0] iv, data_in, key,
    output reg [BLOCK_SIZE-1:0] data_out,
    output reg valid
);
    // Stage 1: Input registration and XOR operation
    reg [BLOCK_SIZE-1:0] prev_block_stage1;
    reg [BLOCK_SIZE-1:0] data_in_stage1;
    reg [BLOCK_SIZE-1:0] key_stage1;
    reg encrypt_stage1;
    reg enable_stage1;
    
    // Stage 2: Cipher operation
    reg [BLOCK_SIZE-1:0] prev_block_stage2;
    reg [BLOCK_SIZE-1:0] cipher_in_stage2;
    reg [BLOCK_SIZE-1:0] key_stage2;
    reg encrypt_stage2;
    reg enable_stage2;
    
    // Stage 3: Output processing
    reg [BLOCK_SIZE-1:0] cipher_out_stage3;
    reg [BLOCK_SIZE-1:0] prev_block_stage3;
    reg encrypt_stage3;
    reg enable_stage3;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input registration and XOR preparation
    always @(posedge clk) begin
        if (rst) begin
            prev_block_stage1 <= iv;
            data_in_stage1 <= 0;
            key_stage1 <= 0;
            encrypt_stage1 <= 0;
            enable_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
            key_stage1 <= key;
            encrypt_stage1 <= encrypt;
            enable_stage1 <= enable;
            valid_stage1 <= enable;
            
            case ({enable, encrypt})
                2'b10: prev_block_stage1 <= data_in; // enable=1, encrypt=0
                default: prev_block_stage1 <= prev_block_stage1; // 其他情况保持不变
            endcase
        end
    end
    
    // Stage 2: Cipher operation
    always @(posedge clk) begin
        if (rst) begin
            cipher_in_stage2 <= 0;
            key_stage2 <= 0;
            encrypt_stage2 <= 0;
            enable_stage2 <= 0;
            prev_block_stage2 <= iv;
            valid_stage2 <= 0;
        end else begin
            key_stage2 <= key_stage1;
            encrypt_stage2 <= encrypt_stage1;
            enable_stage2 <= enable_stage1;
            prev_block_stage2 <= prev_block_stage1;
            valid_stage2 <= valid_stage1;
            
            case (encrypt_stage1)
                1'b1: cipher_in_stage2 <= data_in_stage1 ^ prev_block_stage1;
                1'b0: cipher_in_stage2 <= data_in_stage1;
            endcase
        end
    end
    
    // Stage 3: Output processing
    always @(posedge clk) begin
        if (rst) begin
            cipher_out_stage3 <= 0;
            prev_block_stage3 <= iv;
            encrypt_stage3 <= 0;
            enable_stage3 <= 0;
            valid <= 0;
        end else begin
            // Compute cipher output (split into two stages to reduce critical path)
            cipher_out_stage3 <= cipher_in_stage2 ^ {key_stage2[7:0], key_stage2[31:8]};
            prev_block_stage3 <= prev_block_stage2;
            encrypt_stage3 <= encrypt_stage2;
            enable_stage3 <= enable_stage2;
            valid <= valid_stage2;
            
            case ({enable_stage2, encrypt_stage2})
                2'b11: prev_block_stage3 <= cipher_in_stage2 ^ {key_stage2[7:0], key_stage2[31:8]}; // enable=1, encrypt=1
                default: prev_block_stage3 <= prev_block_stage3; // 其他情况保持不变
            endcase
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 0;
        end else if (enable_stage3) begin
            case (encrypt_stage3)
                1'b1: data_out <= cipher_out_stage3;
                1'b0: data_out <= cipher_out_stage3 ^ prev_block_stage3;
            endcase
        end
    end
endmodule