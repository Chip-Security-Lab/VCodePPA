module Demux_Bidirectional #(parameter N=4, DW=8) (
    inout [DW-1:0] io_port,
    input dir, // 0:in,1:out
    input [N-1:0] sel,
    output [DW-1:0] data_in,
    input [N-1:0][DW-1:0] data_out
);
assign data_in = io_port;
assign io_port = (dir) ? data_out[sel] : {DW{1'bz}};
endmodule