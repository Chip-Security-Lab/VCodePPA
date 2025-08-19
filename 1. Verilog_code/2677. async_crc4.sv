module async_crc4(
    input wire [3:0] data_in,
    output wire [3:0] crc_out
);
    parameter [3:0] POLYNOMIAL = 4'h3; // x^4 + x + 1
    wire [3:0] feedback;
    assign feedback[0] = data_in[0] ^ data_in[3];
    assign feedback[1] = data_in[1] ^ feedback[0];
    assign feedback[2] = data_in[2] ^ feedback[1];
    assign feedback[3] = data_in[3] ^ feedback[2];
    assign crc_out = feedback;
endmodule
