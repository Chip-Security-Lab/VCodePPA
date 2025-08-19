module HoldLatch #(parameter W=4) (
    input clk, hold,
    input [W-1:0] d,
    output reg [W-1:0] q
);
always @(posedge clk)
    if(!hold) q <= d;
endmodule