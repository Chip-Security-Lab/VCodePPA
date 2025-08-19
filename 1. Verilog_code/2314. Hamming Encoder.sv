module hamming_encoder (
    input  [3:0] data_in,
    output [6:0] encoded
);
    // Compute parity bits
    assign encoded[0] = data_in[0] ^ data_in[1] ^ data_in[3]; // p0
    assign encoded[1] = data_in[0] ^ data_in[2] ^ data_in[3]; // p1
    assign encoded[2] = data_in[0];                           // d0
    assign encoded[3] = data_in[1] ^ data_in[2] ^ data_in[3]; // p2
    assign encoded[4] = data_in[1];                           // d1
    assign encoded[5] = data_in[2];                           // d2
    assign encoded[6] = data_in[3];                           // d3
endmodule