module decoder_cascade (
    input en_in,
    input [2:0] addr,
    output [7:0] decoded,
    output en_out
);
    assign {en_out, decoded} = en_in ? {1'b1, (1'b1 << addr)} : 9'h0;
endmodule