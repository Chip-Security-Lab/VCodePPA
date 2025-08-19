//SystemVerilog
module crc5_comb (
    input [4:0] data_in,
    output [4:0] crc_out
);
    // Optimized CRC calculation using direct boolean expressions
    assign crc_out[4] = data_in[3];
    assign crc_out[3] = data_in[2];
    assign crc_out[2] = data_in[1] ^ data_in[4];
    assign crc_out[1] = data_in[0] ^ data_in[4];
    assign crc_out[0] = data_in[4];
endmodule