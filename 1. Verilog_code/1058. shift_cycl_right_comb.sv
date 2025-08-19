module shift_cycl_right_comb #(parameter WIDTH=8) (
    input [WIDTH-1:0] din,
    input [2:0] shift_amt,
    output [WIDTH-1:0] dout
);
assign dout = (din >> shift_amt) | (din << (WIDTH - shift_amt));
endmodule
