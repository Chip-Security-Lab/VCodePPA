module FaultTolMux #(parameter DW=8) (
    input clk,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output reg [DW-1:0] dout,
    output error
);
wire [DW-1:0] primary = din[sel];
wire [DW-1:0] backup = din[~sel];
always @(posedge clk)
    dout <= (^primary[7:4] == primary[3]) ? primary : backup;
assign error = (primary != backup);
endmodule