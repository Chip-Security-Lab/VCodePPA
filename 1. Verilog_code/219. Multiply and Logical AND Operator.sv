module multiply_and_operator (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product,
    output [7:0] and_result
);
    assign product = a * b;            // 乘法
    assign and_result = a & b;         // 与操作
endmodule

