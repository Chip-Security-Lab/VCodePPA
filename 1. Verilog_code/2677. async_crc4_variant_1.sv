//SystemVerilog
module async_crc4(
    input wire [3:0] data_in,
    output wire [3:0] crc_out
);
    parameter [3:0] POLYNOMIAL = 4'h3; // x^4 + x + 1
    
    // Stage 1: Initial XOR operations
    wire [3:0] stage1_xor;
    assign stage1_xor[0] = data_in[0] ^ data_in[3];
    assign stage1_xor[1] = data_in[1] ^ data_in[3];
    assign stage1_xor[2] = data_in[2] ^ data_in[3];
    assign stage1_xor[3] = data_in[3];
    
    // Stage 2: Final XOR operations
    assign crc_out[0] = stage1_xor[0];
    assign crc_out[1] = stage1_xor[1] ^ stage1_xor[0];
    assign crc_out[2] = stage1_xor[2] ^ stage1_xor[1] ^ stage1_xor[0];
    assign crc_out[3] = stage1_xor[3] ^ stage1_xor[2] ^ stage1_xor[1] ^ stage1_xor[0];
    
endmodule