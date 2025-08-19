module add_and_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output [7:0] and_result
);
    assign sum = a + b;        // 加法
    assign and_result = a & b; // 与操作
endmodule
