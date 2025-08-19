// 补码生成子模块
module complement_generator_4bit (
    input signed [3:0] b,
    output [3:0] b_complement
);
    assign b_complement = ~b + 1'b1;
endmodule

// 传播和生成信号子模块
module propagate_generate_4bit (
    input [3:0] a,
    input [3:0] b_complement,
    output [3:0] p,
    output [3:0] g
);
    assign p = a ^ b_complement;
    assign g = a & b_complement;
endmodule

// 前缀计算子模块
module prefix_computation_4bit (
    input [3:0] p,
    input [3:0] g,
    output [3:0] p1,
    output [3:0] g1
);
    assign p1[0] = p[0];
    assign g1[0] = g[0];
    assign p1[1] = p[1] & p[0];
    assign g1[1] = (p[1] & g[0]) | g[1];
    assign p1[2] = p[2] & p[1] & p[0];
    assign g1[2] = (p[2] & p[1] & g[0]) | (p[2] & g[1]) | g[2];
    assign p1[3] = p[3] & p[2] & p[1] & p[0];
    assign g1[3] = (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & g[1]) | (p[3] & g[2]) | g[3];
endmodule

// 进位计算子模块
module carry_computation_4bit (
    input [3:0] g1,
    output [3:0] carry
);
    assign carry[0] = 1'b0;
    assign carry[1] = g1[0];
    assign carry[2] = g1[1];
    assign carry[3] = g1[2];
endmodule

// 结果计算子模块
module result_computation_4bit (
    input [3:0] p,
    input [3:0] carry,
    output signed [3:0] diff,
    output negative
);
    assign diff = p ^ carry;
    assign negative = diff[3];
endmodule

// 顶层模块
module subtractor_signed_check_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff,
    output negative
);
    // 内部信号
    wire [3:0] b_complement;
    wire [3:0] p, g;
    wire [3:0] p1, g1;
    wire [3:0] carry;
    
    // 实例化子模块
    complement_generator_4bit comp_gen (
        .b(b),
        .b_complement(b_complement)
    );
    
    propagate_generate_4bit pg_gen (
        .a(a),
        .b_complement(b_complement),
        .p(p),
        .g(g)
    );
    
    prefix_computation_4bit prefix_comp (
        .p(p),
        .g(g),
        .p1(p1),
        .g1(g1)
    );
    
    carry_computation_4bit carry_comp (
        .g1(g1),
        .carry(carry)
    );
    
    result_computation_4bit result_comp (
        .p(p),
        .carry(carry),
        .diff(diff),
        .negative(negative)
    );
    
endmodule