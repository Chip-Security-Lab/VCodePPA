//SystemVerilog
module Mux2D #(parameter W=4, X=2, Y=2) (
    input [W-1:0] matrix [0:X-1][0:Y-1],
    input [$clog2(X)-1:0] x_sel,
    input [$clog2(Y)-1:0] y_sel,
    output reg [W-1:0] element
);
    always @(*) begin
        // 使用范围检查和直接索引来优化比较逻辑
        if (x_sel < X && y_sel < Y) begin
            element = matrix[x_sel][y_sel];
        end else begin
            element = 0; // 默认值处理
        end
    end
endmodule