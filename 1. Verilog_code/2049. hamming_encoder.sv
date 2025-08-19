module hamming_encoder (
    input wire [3:0] data_in,
    output wire [6:0] hamming_out
);
    assign hamming_out[0] = data_in[0] ^ data_in[1] ^ data_in[3];
    assign hamming_out[1] = data_in[0] ^ data_in[2] ^ data_in[3];
    assign hamming_out[2] = data_in[0];
    assign hamming_out[3] = data_in[1] ^ data_in[2] ^ data_in[3];
    assign hamming_out[4] = data_in[1];
    assign hamming_out[5] = data_in[2];
    assign hamming_out[6] = data_in[3];
endmodule