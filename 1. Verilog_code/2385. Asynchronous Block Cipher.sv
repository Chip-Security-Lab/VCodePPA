module async_block_cipher #(parameter BLOCK_SIZE = 16) (
    input wire [BLOCK_SIZE-1:0] plaintext, key,
    output wire [BLOCK_SIZE-1:0] ciphertext
);
    wire [BLOCK_SIZE-1:0] intermediate;
    // Layer 1: XOR with key
    assign intermediate = plaintext ^ key;
    // Layer 2: Substitution (non-linear operation)
    genvar i;
    generate
        for (i = 0; i < BLOCK_SIZE/4; i = i + 1) begin : sub_blocks
            assign ciphertext[i*4+:4] = intermediate[i*4+:4] + intermediate[((i+1)%(BLOCK_SIZE/4))*4+:4];
        end
    endgenerate
endmodule