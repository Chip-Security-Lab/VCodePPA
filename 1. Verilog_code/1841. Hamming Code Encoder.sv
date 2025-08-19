module hamming_encoder (
    input  wire [3:0] data_in,
    output wire [6:0] encoded_out
);
    // Calculate parity bits p1, p2, p4
    wire p1, p2, p4;
    assign p1 = data_in[0] ^ data_in[1] ^ data_in[3];
    assign p2 = data_in[0] ^ data_in[2] ^ data_in[3];
    assign p4 = data_in[1] ^ data_in[2] ^ data_in[3];
    
    // Hamming code organization: p1,p2,d1,p4,d2,d3,d4
    assign encoded_out = {data_in[3], data_in[2], data_in[1], p4, 
                          data_in[0], p2, p1};
endmodule