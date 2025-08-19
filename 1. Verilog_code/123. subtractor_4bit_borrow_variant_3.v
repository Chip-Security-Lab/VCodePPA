module subtractor_4bit_borrow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);

    wire [3:0] b_comp;
    wire [3:0] sum;
    wire carry_out;

    // 计算b的补码
    assign b_comp = ~b + 1'b1;

    // 使用4位加法器实现减法
    assign {carry_out, sum} = a + b_comp;

    // 输出结果
    assign diff = sum;
    assign borrow = ~carry_out;

endmodule