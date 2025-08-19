module parity_xor(
    input [15:0] data,
    output parity
);
    assign parity = ^data;
endmodule