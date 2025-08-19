module RegInMux #(parameter DW=8) (
    input clk,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output [DW-1:0] dout
);
reg [3:0][DW-1:0] reg_din;
always @(posedge clk) reg_din <= din;
assign dout = reg_din[sel];
endmodule