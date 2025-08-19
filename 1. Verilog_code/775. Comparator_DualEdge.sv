module Comparator_DualEdge #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] x, y,
    output reg         neq
);
    // 将双沿触发替换为单沿触发
    always @(posedge clk) begin
        neq <= (x != y);
    end
endmodule