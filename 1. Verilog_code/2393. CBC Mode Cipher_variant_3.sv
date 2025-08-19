//SystemVerilog
module cbc_mode_cipher #(parameter BLOCK_SIZE = 32) (
    input wire clk, rst,
    input wire enable, encrypt,
    input wire [BLOCK_SIZE-1:0] iv, data_in, key,
    output reg [BLOCK_SIZE-1:0] data_out,
    output reg valid
);
    reg [BLOCK_SIZE-1:0] prev_block;
    wire [BLOCK_SIZE-1:0] cipher_in, cipher_out;
    
    // Encryption function (simplified - would be more complex in practice)
    assign cipher_out = cipher_in ^ {key[7:0], key[31:8]};
    
    // CBC mode logic
    assign cipher_in = encrypt ? (data_in ^ prev_block) : data_in;
    
    always @(posedge clk) begin
        if (rst) begin  // Reset case (reset bit is high, ignore other bits)
            prev_block <= iv;
            valid <= 1'b0;
            data_out <= {BLOCK_SIZE{1'b0}};  // Clear output during reset
        end
        else if (enable && !encrypt) begin  // Enable=1, Encrypt=0, Decrypt mode
            data_out <= cipher_out ^ prev_block;
            prev_block <= data_in;
            valid <= 1'b1;
        end
        else if (enable && encrypt) begin  // Enable=1, Encrypt=1, Encrypt mode
            data_out <= cipher_out;
            prev_block <= cipher_out;
            valid <= 1'b1;
        end
        else begin  // Enable=0, not in reset
            valid <= 1'b0;
            // Hold other values
        end
    end
endmodule