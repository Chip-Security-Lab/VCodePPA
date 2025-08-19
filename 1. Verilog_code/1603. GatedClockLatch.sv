module GatedClockLatch #(parameter DW=8) (
    input clk, gate,
    input [DW-1:0] d,
    output reg [DW-1:0] q
);
wire gclk = clk & gate;
always @(posedge gclk)
    q <= d;
endmodule