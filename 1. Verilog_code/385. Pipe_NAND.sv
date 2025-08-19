module Pipe_NAND(
    input clk,
    input [15:0] a, b,
    output reg [15:0] out
);
    always @(posedge clk) begin
        out <= ~(a & b);  // 流水线寄存器
    end
endmodule
