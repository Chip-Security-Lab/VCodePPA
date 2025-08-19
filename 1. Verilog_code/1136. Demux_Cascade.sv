module Demux_Cascade #(parameter DW=8, DEPTH=2) (
    input clk,
    input [DW-1:0] data_in,
    input [$clog2(DEPTH+1)-1:0] addr,
    output [DEPTH:0][DW-1:0] data_out
);
assign data_out[0] = (addr == 0) ? data_in : 0;
generate genvar i;
for(i=1; i<=DEPTH; i=i+1) begin
    assign data_out[i] = (addr == i) ? data_in : data_out[i-1];
end
endgenerate
endmodule