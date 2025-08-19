module unsigned_subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);

    wire [7:0] b_comp;
    wire [7:0] sum;
    wire carry_out;
    wire [1:0] g0, g1, g2, g3;
    wire [1:0] p0, p1, p2, p3;
    wire [1:0] c0, c1, c2, c3;
    wire [1:0] s0, s1, s2, s3;

    // 计算b的补码
    assign b_comp = ~b + 1'b1;

    // 生成和传播信号
    assign g0 = a[1:0] & b_comp[1:0];
    assign p0 = a[1:0] ^ b_comp[1:0];
    assign g1 = a[3:2] & b_comp[3:2];
    assign p1 = a[3:2] ^ b_comp[3:2];
    assign g2 = a[5:4] & b_comp[5:4];
    assign p2 = a[5:4] ^ b_comp[5:4];
    assign g3 = a[7:6] & b_comp[7:6];
    assign p3 = a[7:6] ^ b_comp[7:6];

    // 进位计算
    assign c0 = g0 | (p0 & 1'b1);
    assign c1 = g1 | (p1 & c0);
    assign c2 = g2 | (p2 & c1);
    assign c3 = g3 | (p3 & c2);

    // 和计算
    assign s0 = p0 ^ 1'b1;
    assign s1 = p1 ^ c0;
    assign s2 = p2 ^ c1;
    assign s3 = p3 ^ c2;

    // 组合最终结果
    assign sum = {s3, s2, s1, s0};
    assign carry_out = c3[1];

    // 输出结果
    assign diff = sum;

endmodule