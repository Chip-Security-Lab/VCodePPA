module Demux_SyncEn #(parameter DW=8, AW=3) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output reg [(1<<AW)-1:0][DW-1:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) data_out <= 0;
    else if (en) begin
        data_out <= 0;
        data_out[addr] <= data_in;
    end
end
endmodule
