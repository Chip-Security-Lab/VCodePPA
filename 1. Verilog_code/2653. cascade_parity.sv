module cascade_parity (
    input [7:0] data,
    output parity
);
wire [3:0] nib_par;
assign nib_par[0] = ^data[3:0];
assign nib_par[1] = ^data[7:4];
assign parity = ^nib_par;
endmodule