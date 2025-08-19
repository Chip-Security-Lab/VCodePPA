module CrossMux #(parameter DW=8) (
    input clk,
    input [3:0][DW-1:0] in,
    input [1:0] x_sel, y_sel,
    output reg [DW+1:0] out
);
wire parity = ^in[x_sel];
always @(posedge clk)
    out <= {parity, in[x_sel], y_sel};
endmodule