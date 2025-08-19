module DiffLatch #(parameter DW=8) (
    input clk,
    input [DW-1:0] d_p, d_n,
    output reg [DW-1:0] q
);
always @(posedge clk)
    q <= d_p ^ d_n;
endmodule