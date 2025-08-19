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
        if (rst) begin
            prev_block <= iv;
            valid <= 0;
        end else if (enable) begin
            if (encrypt) begin
                data_out <= cipher_out;
                prev_block <= cipher_out;
            end else begin
                data_out <= cipher_out ^ prev_block;
                prev_block <= data_in;
            end
            valid <= 1;
        end else valid <= 0;
    end
endmodule