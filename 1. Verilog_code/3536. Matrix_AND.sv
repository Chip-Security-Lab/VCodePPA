module Matrix_AND(
    input [3:0] row, col,
    output [7:0] matrix_res
);
    assign matrix_res = {row, col} & 8'h55; // 矩阵位与操作
endmodule
