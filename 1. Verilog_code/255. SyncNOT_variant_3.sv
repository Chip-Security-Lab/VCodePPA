//SystemVerilog
module SyncNOT(
    input clk,
    input [15:0] async_in,
    output reg [15:0] synced_not
);
    reg [15:0] synced_in;
    
    always @(posedge clk) begin
        synced_in <= async_in;    // 先同步输入信号
    end
    
    always @(posedge clk) begin
        synced_not <= ~synced_in; // 基于同步信号进行取反操作
    end
endmodule