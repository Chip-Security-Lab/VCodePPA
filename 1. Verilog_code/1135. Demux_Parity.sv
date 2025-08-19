module Demux_Parity #(parameter DW=9) (
    input [DW-2:0] data_in,
    input [2:0] addr,
    output reg [7:0][DW-1:0] data_out
);
wire parity = ^data_in;
always @(*) begin
    data_out = 0;
    data_out[addr] = {parity, data_in};
end
endmodule