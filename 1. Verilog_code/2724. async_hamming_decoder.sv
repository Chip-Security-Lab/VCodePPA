module async_hamming_decoder(
    input [11:0] encoded_in,
    output [7:0] data_out,
    output single_err, double_err
);
    wire [3:0] syndrome;
    wire parity_check;
    
    assign syndrome[0] = encoded_in[0] ^ encoded_in[2] ^ encoded_in[4] ^ encoded_in[6] ^ encoded_in[8] ^ encoded_in[10];
    assign syndrome[1] = encoded_in[1] ^ encoded_in[2] ^ encoded_in[5] ^ encoded_in[6] ^ encoded_in[9] ^ encoded_in[10];
    assign syndrome[2] = encoded_in[3] ^ encoded_in[4] ^ encoded_in[5] ^ encoded_in[6];
    assign syndrome[3] = encoded_in[7] ^ encoded_in[8] ^ encoded_in[9] ^ encoded_in[10];
    assign parity_check = ^encoded_in;
    assign single_err = |syndrome & ~parity_check;
    assign double_err = |syndrome & parity_check;
    assign data_out = {encoded_in[10:7], encoded_in[6:4], encoded_in[2]};
endmodule