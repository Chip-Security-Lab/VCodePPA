// 顶层模块：8位减法器
module subtractor_8bit_borrow_detect (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    // 实例化8位减法器子模块
    subtractor_8bit u_subtractor (
        .a(a),
        .b(b),
        .diff(diff),
        .borrow(borrow)
    );

endmodule

// 8位减法器子模块
module subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    wire [7:0] b_comp = ~b;
    wire [7:0] sum;
    wire cout;

    // 使用曼彻斯特进位链加法器
    manchester_adder_8bit u_adder (
        .a(a),
        .b(b_comp),
        .cin(1'b1),
        .sum(sum),
        .cout(cout)
    );

    assign diff = sum;
    assign borrow = ~cout;

endmodule

// 8位曼彻斯特进位链加法器
module manchester_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);

    wire [7:0] g = a & b;
    wire [7:0] p = a ^ b;
    wire [7:0] c;

    // 曼彻斯特进位链计算
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign cout = g[7] | (p[7] & c[7]);

    // 和计算
    assign sum = p ^ c;

endmodule