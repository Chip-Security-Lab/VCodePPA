module RegEnMux #(parameter DW=8) (
    input clk, en,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output reg [DW-1:0] dout
);
always @(posedge clk)
    if(en) dout <= din[sel];
endmodule