//SystemVerilog
module MuxSyncReg #(parameter DW=8, AW=3) (
    input clk, 
    input rst_n, 
    input [AW-1:0] sel,
    input [2**AW*DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    data_out <= (!rst_n) ? {DW{1'b0}} : data_in[sel*DW +: DW];
end
endmodule