module Matrix_NAND(
    input [3:0] row, col,
    output [7:0] mat_res
);
    assign mat_res = ~({row, col} & 8'hAA);
endmodule
