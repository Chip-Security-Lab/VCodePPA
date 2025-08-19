module Pipeline_XNOR(
    input clk,
    input [15:0] a, b,
    output reg [15:0] out
);
    always @(posedge clk) begin
        out <= ~(a ^ b); // 流水线寄存
    end
endmodule
