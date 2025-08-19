module GrayLatch #(parameter DW=4) (
    input clk, en,
    input [DW-1:0] bin_in,
    output reg [DW-1:0] gray_out
);
always @(posedge clk)
    if(en) gray_out <= bin_in ^ (bin_in >> 1);
endmodule