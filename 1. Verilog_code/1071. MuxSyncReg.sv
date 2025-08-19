module MuxSyncReg #(parameter DW=8, AW=3) (
    input clk, rst_n, 
    input [AW-1:0] sel,
    input [2**AW*DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
always @(posedge clk or negedge rst_n)
    if(!rst_n) data_out <= 0;
    else data_out <= data_in[sel*DW +: DW];
endmodule