module subtractor_signed_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff
);

    // 内部信号
    wire signed [3:0] b_complement;
    wire signed [3:0] sum;
    wire carry_out;

    // 补码转换子模块
    complement_converter complement_inst (
        .in(b),
        .out(b_complement)
    );

    // 并行前缀加法器子模块
    parallel_prefix_adder_4bit adder_inst (
        .a(a),
        .b(b_complement),
        .sum(sum),
        .carry_out(carry_out)
    );

    // 结果选择子模块
    result_selector selector_inst (
        .sum(sum),
        .carry_out(carry_out),
        .diff(diff)
    );

endmodule

// 补码转换子模块
module complement_converter (
    input signed [3:0] in,
    output signed [3:0] out
);
    assign out = ~in + 1'b1;
endmodule

// 4位并行前缀加法器子模块
module parallel_prefix_adder_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] sum,
    output carry_out
);
    // 生成和传播信号
    wire [3:0] g, p;
    // 中间传播信号
    wire [3:0] g1, p1;
    wire [3:0] g2, p2;
    // 进位信号
    wire [4:0] c;

    // 计算生成和传播信号
    assign g = a & b;
    assign p = a ^ b;

    // 第一级前缀计算
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];

    // 第二级前缀计算
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];

    // 计算进位
    assign c[0] = 1'b0;
    assign c[1] = g2[0];
    assign c[2] = g2[1];
    assign c[3] = g2[2];
    assign c[4] = g2[3];

    // 计算和
    assign sum = p ^ c[3:0];
    assign carry_out = c[4];

endmodule

// 结果选择子模块
module result_selector (
    input signed [3:0] sum,
    input carry_out,
    output signed [3:0] diff
);
    assign diff = sum;
endmodule