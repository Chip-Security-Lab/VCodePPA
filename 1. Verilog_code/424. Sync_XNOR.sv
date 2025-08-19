module Sync_XNOR(
    input clk,
    input [7:0] sig_a, sig_b,
    output reg [7:0] q
);
    always @(posedge clk) begin
        q <= ~(sig_a ^ sig_b); // 寄存器输出
    end
endmodule
