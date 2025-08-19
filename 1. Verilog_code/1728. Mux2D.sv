module Mux2D #(parameter W=4, X=2, Y=2) (
    input [W-1:0] matrix [0:X-1][0:Y-1], // 修改数组声明
    input [$clog2(X)-1:0] x_sel,
    input [$clog2(Y)-1:0] y_sel,
    output reg [W-1:0] element
);
    integer i, j;
    always @(*) begin
        element = 0;
        for (i = 0; i < X; i = i + 1) begin
            for (j = 0; j < Y; j = j + 1) begin
                if (i == x_sel && j == y_sel)
                    element = matrix[i][j];
            end
        end
    end
endmodule