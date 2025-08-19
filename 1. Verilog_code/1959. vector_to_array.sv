module vector_to_array #(
    parameter ROW_NUM = 3,
    parameter COL_NUM = 3,
    parameter DATA_W = 8
)(
    input [ROW_NUM*COL_NUM*DATA_W-1:0] vector,
    output reg [ROW_NUM-1:0][COL_NUM-1:0][DATA_W-1:0] matrix
);
    // 修改：使用generate块替代always块中的integer
    genvar row, col;
    
    generate
        for (row = 0; row < ROW_NUM; row = row + 1) begin: row_gen
            for (col = 0; col < COL_NUM; col = col + 1) begin: col_gen
                always @(*) begin
                    matrix[row][col] = vector[(row*COL_NUM+col)*DATA_W +: DATA_W];
                end
            end
        end
    endgenerate
endmodule