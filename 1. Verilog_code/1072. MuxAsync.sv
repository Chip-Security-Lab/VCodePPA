module MuxAsync #(parameter DW=8, AW=3) (
    input [AW-1:0] channel,
    input [2**AW-1:0][DW-1:0] din,
    output [DW-1:0] dout
);
assign dout = din[channel];
endmodule