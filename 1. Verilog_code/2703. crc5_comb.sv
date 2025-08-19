module crc5_comb (
    input [4:0] data_in,
    output [4:0] crc_out
);
assign crc_out = (data_in << 1) ^ ((data_in[4]) ? 5'h15 : 5'h00);
endmodule