//SystemVerilog
module Demux_AutoPipe #(parameter DW=8, AW=2) (
    input clk, rst,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [(1<<AW)-1:0][DW-1:0] dout
);
    reg [AW-1:0] addr_reg;
    reg [DW-1:0] din_reg;
    reg [(1<<AW)-1:0][DW-1:0] pipe_reg;
    
    always @(posedge clk) begin
        // 使用条件运算符替代if-else结构
        addr_reg <= rst ? '0 : addr;
        din_reg <= rst ? '0 : din;
        pipe_reg <= rst ? '0 : (addr_reg == addr_reg) ? (pipe_reg & ~({{(DW){1'b1}}} << (addr_reg*DW))) | (din_reg << (addr_reg*DW)) : pipe_reg;
        dout <= rst ? '0 : pipe_reg;
    end
endmodule