module Sync_AND(
    input clk,
    input [7:0] signal_a, signal_b,
    output reg [7:0] reg_out
);
    always @(posedge clk) begin
        reg_out <= signal_a & signal_b; // 时钟驱动输出
    end
endmodule
