module RstInitMux #(parameter DW=8) (
    input clk, rst,
    input [2:0] sel,
    input [7:0][DW-1:0] din,
    output reg [DW-1:0] dout
);
always @(posedge clk)
    dout <= rst ? din[0] : din[sel];
endmodule