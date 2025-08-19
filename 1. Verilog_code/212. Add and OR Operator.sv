module add_nor_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output [7:0] nor_result
);
    assign sum = a + b;                // 加法
    assign nor_result = ~(a | b);       // 或非
endmodule
