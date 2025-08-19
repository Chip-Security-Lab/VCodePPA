module subtractor_4bit_borrow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);

    wire [3:0] b_comp;
    wire [3:0] carry;
    wire [3:0] sum;

    // 计算补码
    assign b_comp = ~b + 1'b1;

    // 优化后的先行进位计算
    assign carry[0] = 1'b0;
    assign carry[1] = (a[0] & b_comp[0]) | (a[0] & carry[0]) | (b_comp[0] & carry[0]);
    assign carry[2] = (a[1] & b_comp[1]) | (a[1] & carry[1]) | (b_comp[1] & carry[1]);
    assign carry[3] = (a[2] & b_comp[2]) | (a[2] & carry[2]) | (b_comp[2] & carry[2]);
    assign borrow = (a[3] & b_comp[3]) | (a[3] & carry[3]) | (b_comp[3] & carry[3]);

    // 计算差
    assign sum[0] = a[0] ^ b_comp[0] ^ carry[0];
    assign sum[1] = a[1] ^ b_comp[1] ^ carry[1];
    assign sum[2] = a[2] ^ b_comp[2] ^ carry[2];
    assign sum[3] = a[3] ^ b_comp[3] ^ carry[3];

    assign diff = sum;

endmodule