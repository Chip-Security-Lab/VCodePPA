module array_flattener #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input [ROWS-1:0][COLS-1:0][CELL_WIDTH-1:0] matrix,
    output [ROWS*COLS*CELL_WIDTH-1:0] flat_vector
);
    genvar r, c;
    generate
        for (r = 0; r < ROWS; r = r + 1) begin: row_gen  // 添加命名的generate块
            for (c = 0; c < COLS; c = c + 1) begin: col_gen
                assign flat_vector[(r*COLS+c)*CELL_WIDTH +: CELL_WIDTH] = matrix[r][c];
            end
        end
    endgenerate
endmodule