module BitPlane #(W=8) (
    input [W-1:0] din,
    output [W/2-1:0] dout
);
assign dout = {din[W-1:W/2], din[W/2-1:0]};
endmodule
