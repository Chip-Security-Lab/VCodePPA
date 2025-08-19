module async_hamming_enc_8bit(
    input [7:0] din,
    output [11:0] enc_out
);
    // Calculate parity bits
    assign enc_out[0] = din[0] ^ din[1] ^ din[3] ^ din[4] ^ din[6];
    assign enc_out[1] = din[0] ^ din[2] ^ din[3] ^ din[5] ^ din[6];
    assign enc_out[2] = din[0];
    assign enc_out[3] = din[1] ^ din[2] ^ din[3] ^ din[7];
    assign enc_out[4] = din[1];
    assign enc_out[5] = din[2];
    assign enc_out[6] = din[3];
    assign enc_out[7] = din[4];
    assign enc_out[8] = din[5];
    assign enc_out[9] = din[6];
    assign enc_out[10] = din[7];
    assign enc_out[11] = ^enc_out[10:0]; // Overall parity for SEC-DED
endmodule