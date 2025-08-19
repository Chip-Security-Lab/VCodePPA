module Multiplier3(
    input clk,
    input [3:0] data_a, data_b,
    output reg [7:0] mul_result
);
    always @(posedge clk) begin
        mul_result <= data_a * data_b;  // 时钟驱动计算
    end
endmodule