module subtractor_signed_check_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff,
    output negative
);

    // 实例化并行前缀减法器子模块
    parallel_prefix_subtractor_4bit u_subtractor (
        .a(a),
        .b(b),
        .diff(diff)
    );

    // 实例化符号检测子模块
    sign_detector u_sign_detector (
        .diff(diff),
        .negative(negative)
    );

endmodule

// 并行前缀减法器子模块
module parallel_prefix_subtractor_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff
);
    wire [3:0] b_comp;
    wire [3:0] g, p;
    wire [3:0] c;
    
    // 计算补码
    assign b_comp = ~b + 1'b1;
    
    // 生成和传播信号
    assign g = a & b_comp;
    assign p = a ^ b_comp;
    
    // 并行前缀计算进位
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & g[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    // 计算最终结果
    assign diff = p ^ {c[2:0], 1'b0};
endmodule

// 符号检测子模块
module sign_detector (
    input signed [3:0] diff,
    output negative
);
    assign negative = (diff[3] == 1);
endmodule