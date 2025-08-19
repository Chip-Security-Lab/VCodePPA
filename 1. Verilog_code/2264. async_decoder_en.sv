module async_decoder_en(
    input [1:0] addr,
    input enable,
    output [3:0] decode_out
);
    assign decode_out = enable ? (4'b0001 << addr) : 4'b0000;
endmodule