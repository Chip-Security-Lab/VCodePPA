module parity_tree(
    input [15:0] data,
    output even_par
);
    assign even_par = ~^data;  // 偶校验
endmodule