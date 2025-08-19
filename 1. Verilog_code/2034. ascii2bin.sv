module ascii2bin (
    input [7:0] ascii_in,
    output [6:0] bin_out
);
    assign bin_out = ^{ascii_in} ? ascii_in[6:0] : 7'b0;
endmodule