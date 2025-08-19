module complex_expr(
    input a, b, c, d,
    output y
);
    assign y = (a | (b & c)) ^ (d ? ~b : c);  // 混合逻辑操作
endmodule