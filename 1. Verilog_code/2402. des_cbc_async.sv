module des_cbc_async (
    input [63:0] din, iv,
    input [55:0] key,
    output [63:0] dout
);
    wire [63:0] xor_stage = din ^ iv;
    wire [63:0] feistel_out;
    
    // Simplified Feistel network
    assign feistel_out = {xor_stage[31:0], xor_stage[63:32] ^ key[31:0]};
    assign dout = {feistel_out[15:0], feistel_out[63:16]};
endmodule
