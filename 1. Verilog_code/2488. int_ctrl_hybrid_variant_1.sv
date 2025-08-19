//SystemVerilog
`timescale 1ns / 1ps
module int_ctrl_hybrid #(
    parameter HIGH_PRI = 3
)(
    input clk, rst_n,
    input [7:0] req,
    input [7:0] multiplicand, // 新增乘法器输入
    input [7:0] multiplier,   // 新增乘法器输入
    output reg [2:0] pri_code,
    output reg intr_flag,
    output reg [15:0] product // 新增乘法器输出
);
    // 优化的优先级编码逻辑
    reg [2:0] next_pri_code;
    wire has_request = |req;
    
    // 优化的优先级逻辑，使用级联的条件判断
    always @(*) begin
        if (req[7])
            next_pri_code = 3'h7;
        else if (req[6])
            next_pri_code = 3'h6;
        else if (req[5])
            next_pri_code = 3'h5;
        else if (req[4])
            next_pri_code = 3'h4;
        else if (req[3])
            next_pri_code = 3'h3;
        else if (req[2])
            next_pri_code = 3'h2;
        else if (req[1])
            next_pri_code = 3'h1;
        else
            next_pri_code = 3'h0;
    end
    
    // Wallace树乘法器的部分积生成
    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    assign pp0 = multiplier[0] ? multiplicand : 8'b0;
    assign pp1 = multiplier[1] ? {multiplicand[6:0], 1'b0} : 9'b0;
    assign pp2 = multiplier[2] ? {multiplicand[5:0], 2'b0} : 10'b0;
    assign pp3 = multiplier[3] ? {multiplicand[4:0], 3'b0} : 11'b0;
    assign pp4 = multiplier[4] ? {multiplicand[3:0], 4'b0} : 12'b0;
    assign pp5 = multiplier[5] ? {multiplicand[2:0], 5'b0} : 13'b0;
    assign pp6 = multiplier[6] ? {multiplicand[1:0], 6'b0} : 14'b0;
    assign pp7 = multiplier[7] ? {multiplicand[0], 7'b0} : 15'b0;
    
    // Wallace树第一级 - 3:2压缩
    wire [14:0] s1_1, c1_1;
    wallace_csa3_2 #(15) csa1_1 (
        .a({7'b0, pp0}),
        .b({6'b0, pp1, 1'b0}),
        .c({5'b0, pp2, 2'b0}),
        .sum(s1_1),
        .carry(c1_1)
    );
    
    wire [14:0] s1_2, c1_2;
    wallace_csa3_2 #(15) csa1_2 (
        .a({4'b0, pp3, 3'b0}),
        .b({3'b0, pp4, 4'b0}),
        .c({2'b0, pp5, 5'b0}),
        .sum(s1_2),
        .carry(c1_2)
    );
    
    // Wallace树第二级 - 3:2压缩
    wire [14:0] s2_1, c2_1;
    wallace_csa3_2 #(15) csa2_1 (
        .a({1'b0, pp6, 6'b0}),
        .b({pp7, 7'b0}),
        .c(s1_1),
        .sum(s2_1),
        .carry(c2_1)
    );
    
    wire [14:0] s2_2, c2_2;
    wallace_csa3_2 #(15) csa2_2 (
        .a(c1_1),
        .b(s1_2),
        .c(c1_2),
        .sum(s2_2),
        .carry(c2_2)
    );
    
    // Wallace树第三级 - 3:2压缩
    wire [15:0] s3_1, c3_1;
    wallace_csa3_2 #(16) csa3_1 (
        .a({1'b0, s2_1}),
        .b({1'b0, c2_1}),
        .c({1'b0, s2_2}),
        .sum(s3_1),
        .carry(c3_1)
    );
    
    // Wallace树最后级 - 最终加法
    wire [15:0] final_sum;
    assign final_sum = s3_1 + {c3_1[14:0], 1'b0} + {1'b0, c2_2};
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pri_code <= 3'b0;
            intr_flag <= 1'b0;
            product <= 16'b0;
        end else begin
            pri_code <= next_pri_code;
            intr_flag <= has_request;
            product <= final_sum;
        end
    end
endmodule

// 3:2压缩器模块 - Wallace树的基本构建块
module wallace_csa3_2 #(
    parameter WIDTH = 15
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [WIDTH-1:0] c,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] carry
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: csa_slice
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign carry[i] = (a[i] & b[i]) | (b[i] & c[i]) | (a[i] & c[i]);
        end
    endgenerate
endmodule