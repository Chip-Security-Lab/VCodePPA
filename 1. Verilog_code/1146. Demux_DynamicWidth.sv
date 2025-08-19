module Demux_DynamicWidth #(parameter MAX_DW=32) (
    input clk,
    input [5:0] width_config,
    input [MAX_DW-1:0] data_in,
    output reg [3:0][MAX_DW-1:0] data_out
);
wire [MAX_DW-1:0] mask = (1 << width_config) - 1;
always @(posedge clk) begin
    data_out[0] <= data_in & mask;
    data_out[1] <= data_in & ~mask;
end
endmodule
