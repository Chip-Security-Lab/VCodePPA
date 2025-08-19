//SystemVerilog
// 顶层模块
module multiplier_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);

    // 部分积生成模块接口
    wire [3:0][3:0] partial_products;
    
    // 第一级加法器接口
    wire [3:0] sum_stage1_0, sum_stage1_1;
    wire [3:0] carry_stage1_0, carry_stage1_1;
    
    // 第二级加法器接口
    wire [4:0] sum_stage2;
    wire [4:0] carry_stage2;

    // 实例化部分积生成模块
    partial_product_generator pp_gen (
        .a(a),
        .b(b),
        .partial_products(partial_products)
    );

    // 实例化第一级加法器模块
    adder_stage1 stage1 (
        .partial_products(partial_products),
        .sum_0(sum_stage1_0),
        .sum_1(sum_stage1_1),
        .carry_0(carry_stage1_0),
        .carry_1(carry_stage1_1)
    );

    // 实例化第二级加法器模块
    adder_stage2 stage2 (
        .sum_stage1_0(sum_stage1_0),
        .sum_stage1_1(sum_stage1_1),
        .carry_stage1_0(carry_stage1_0),
        .carry_stage1_1(carry_stage1_1),
        .sum_stage2(sum_stage2),
        .carry_stage2(carry_stage2)
    );

    // 最终结果组合
    assign product = {carry_stage2, sum_stage2};

endmodule

// 部分积生成模块
module partial_product_generator (
    input [3:0] a,
    input [3:0] b,
    output [3:0][3:0] partial_products
);

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : PARTIAL_PRODUCTS
            assign partial_products[i] = a & {4{b[i]}};
        end
    endgenerate

endmodule

// 第一级加法器模块
module adder_stage1 (
    input [3:0][3:0] partial_products,
    output [3:0] sum_0,
    output [3:0] sum_1,
    output [3:0] carry_0,
    output [3:0] carry_1
);

    carry_lookahead_adder_4bit adder_0 (
        .a(partial_products[0]),
        .b({1'b0, partial_products[1][2:0]}),
        .cin(1'b0),
        .sum(sum_0),
        .cout(carry_0)
    );

    carry_lookahead_adder_4bit adder_1 (
        .a(partial_products[2]),
        .b({1'b0, partial_products[3][2:0]}),
        .cin(1'b0),
        .sum(sum_1),
        .cout(carry_1)
    );

endmodule

// 第二级加法器模块
module adder_stage2 (
    input [3:0] sum_stage1_0,
    input [3:0] sum_stage1_1,
    input [3:0] carry_stage1_0,
    input [3:0] carry_stage1_1,
    output [4:0] sum_stage2,
    output [4:0] carry_stage2
);

    carry_lookahead_adder_5bit adder (
        .a({carry_stage1_0, sum_stage1_0}),
        .b({carry_stage1_1, sum_stage1_1}),
        .cin(1'b0),
        .sum(sum_stage2),
        .cout(carry_stage2)
    );

endmodule

// 4位先行进位加法器模块
module carry_lookahead_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] g, p;
    wire [3:0] carry;
    
    assign g = a & b;
    assign p = a ^ b;
    
    assign carry[0] = g[0] | (p[0] & cin);
    assign carry[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign carry[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign carry[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ carry[0];
    assign sum[2] = p[2] ^ carry[1];
    assign sum[3] = p[3] ^ carry[2];
    
    assign cout = carry[3];
endmodule

// 5位先行进位加法器模块
module carry_lookahead_adder_5bit (
    input [4:0] a,
    input [4:0] b,
    input cin,
    output [4:0] sum,
    output cout
);
    wire [4:0] g, p;
    wire [4:0] carry;
    
    assign g = a & b;
    assign p = a ^ b;
    
    assign carry[0] = g[0] | (p[0] & cin);
    assign carry[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign carry[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign carry[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    assign carry[4] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & cin);
    
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ carry[0];
    assign sum[2] = p[2] ^ carry[1];
    assign sum[3] = p[3] ^ carry[2];
    assign sum[4] = p[4] ^ carry[3];
    
    assign cout = carry[4];
endmodule