module shift_arith_async #(parameter W=8) (
    input signed [W-1:0] din,
    input [2:0] shift,
    output signed [W-1:0] dout
);
assign dout = din >>> shift;
endmodule