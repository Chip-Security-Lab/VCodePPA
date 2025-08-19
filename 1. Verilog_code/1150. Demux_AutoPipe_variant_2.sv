//SystemVerilog
module Demux_AutoPipe #(parameter DW=8, AW=2) (
    input clk, rst,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [(1<<AW)-1:0][DW-1:0] dout
);
    reg [AW-1:0] addr_reg;
    reg [DW-1:0] din_reg;
    
    always_ff @(posedge clk) begin
        if(rst) begin
            addr_reg <= {AW{1'b0}};
            din_reg <= {DW{1'b0}};
            dout <= {((1<<AW)*DW){1'b0}};
        end else begin
            // 流水线第一级：寄存输入信号
            addr_reg <= addr;
            din_reg <= din;
            
            // 流水线第二级：直接更新输出寄存器
            // 通过使用计算型赋值减少中间寄存器，同时保持功能
            for(int i = 0; i < (1<<AW); i++) begin
                if(i == addr_reg)
                    dout[i] <= din_reg;
            end
        end
    end
endmodule