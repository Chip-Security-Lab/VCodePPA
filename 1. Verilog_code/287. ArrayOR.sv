module ArrayOR(
    input [3:0] row, col,
    output [7:0] matrix_or
);
    assign matrix_or = {row, col} | 8'hAA;
endmodule
