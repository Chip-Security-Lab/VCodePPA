module ChecksumMux #(parameter DW=8) (
    input clk,
    input [3:0][DW-1:0] din,
    input [1:0] sel,
    output reg [DW+3:0] out
);
wire [DW-1:0] data = din[sel];
always @(posedge clk) 
    out <= {^data, data, sel};
endmodule