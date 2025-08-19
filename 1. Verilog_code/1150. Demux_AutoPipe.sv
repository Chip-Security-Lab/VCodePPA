module Demux_AutoPipe #(parameter DW=8, AW=2) (
    input clk, rst,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [(1<<AW)-1:0][DW-1:0] dout
);
reg [(1<<AW)-1:0][DW-1:0] pipe_reg;
always @(posedge clk) begin
    if(rst) begin
        dout <= 0;
        pipe_reg <= 0;
    end else begin
        pipe_reg[addr] <= din;
        dout <= pipe_reg;
    end
end
endmodule
