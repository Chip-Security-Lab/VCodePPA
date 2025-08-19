module DoubleBuffer #(parameter W=12) (
    input clk, load,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);
reg [W-1:0] buf1, buf2;
always @(posedge clk)
    if(load) {buf2, buf1} <= {buf1, data_in};
assign data_out = buf2;
endmodule