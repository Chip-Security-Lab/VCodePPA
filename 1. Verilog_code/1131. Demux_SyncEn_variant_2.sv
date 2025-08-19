//SystemVerilog
module Demux_SyncEn #(parameter DW=8, AW=3) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output reg [(1<<AW)-1:0][DW-1:0] data_out
);
    // 使用独热码编码以减少地址译码延迟
    reg [(1<<AW)-1:0] addr_one_hot;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= '0;
            addr_one_hot <= '0;
        end
        else if (en) begin
            // 清零所有输出
            data_out <= '0;
            // 独热码地址译码
            addr_one_hot <= (1'b1 << addr);
            // 根据独热码选择输出通道
            data_out[addr] <= data_in;
        end
    end
endmodule