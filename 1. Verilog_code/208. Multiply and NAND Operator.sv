module multiply_nand_operator (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product,
    output [7:0] nand_result
);
    assign product = a * b;         // 乘法
    assign nand_result = ~(a & b);  // 与非
endmodule
