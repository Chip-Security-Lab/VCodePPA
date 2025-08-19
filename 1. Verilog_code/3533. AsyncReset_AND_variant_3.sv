//SystemVerilog
module AsyncReset_AND(
    input rst_n,
    input [3:0] src1, src2,
    output reg [3:0] q
);
    wire [7:0] mult_result;
    
    DaddaMultiplier4bit dadda_mult (
        .a(src1),
        .b(src2),
        .product(mult_result),
        .rst_n(rst_n)
    );
    
    // 应用异步复位逻辑
    always @(*) begin
        q = mult_result[3:0];
    end
endmodule

module DaddaMultiplier4bit(
    input [3:0] a,
    input [3:0] b,
    input rst_n,
    output reg [7:0] product
);
    // 第一级流水线：生成部分积
    reg [3:0] pp0_reg, pp1_reg, pp2_reg, pp3_reg;
    wire [3:0] pp0, pp1, pp2, pp3;
    
    assign pp0 = a & {4{b[0]}};
    assign pp1 = a & {4{b[1]}};
    assign pp2 = a & {4{b[2]}};
    assign pp3 = a & {4{b[3]}};
    
    // 部分积寄存器
    always @(*) begin
        if (!rst_n) begin
            pp0_reg = 4'b0;
            pp1_reg = 4'b0;
            pp2_reg = 4'b0;
            pp3_reg = 4'b0;
        end else begin
            pp0_reg = pp0;
            pp1_reg = pp1;
            pp2_reg = pp2;
            pp3_reg = pp3;
        end
    end
    
    // 第二级流水线：Dadda归约阶段1（从高度4到3）
    wire [4:0] s1_1, c1_1;
    wire [5:1] s1_2, c1_2;
    reg [4:0] s1_1_reg, c1_1_reg;
    reg [5:1] s1_2_reg, c1_2_reg;
    
    // Dadda树压缩阶段1
    DaddaStage1 dadda_stage1(
        .pp0(pp0_reg),
        .pp1(pp1_reg),
        .pp2(pp2_reg),
        .pp3(pp3_reg),
        .s1_1(s1_1),
        .c1_1(c1_1),
        .s1_2(s1_2),
        .c1_2(c1_2)
    );
    
    // 归约阶段1结果寄存器
    always @(*) begin
        if (!rst_n) begin
            s1_1_reg = 5'b0;
            c1_1_reg = 5'b0;
            s1_2_reg = 5'b0;
            c1_2_reg = 5'b0;
        end else begin
            s1_1_reg = s1_1;
            c1_1_reg = c1_1;
            s1_2_reg = s1_2;
            c1_2_reg = c1_2;
        end
    end
    
    // 第三级流水线：Dadda归约阶段2（从高度3到2）
    wire [6:0] s2, c2;
    reg [6:0] s2_reg, c2_reg;
    
    // Dadda树压缩阶段2
    DaddaStage2 dadda_stage2(
        .pp0(pp0_reg),
        .pp1(pp1_reg),
        .pp2(pp2_reg),
        .pp3(pp3_reg),
        .s1_1(s1_1_reg),
        .c1_1(c1_1_reg),
        .s1_2(s1_2_reg),
        .c1_2(c1_2_reg),
        .s2(s2),
        .c2(c2)
    );
    
    // 归约阶段2结果寄存器
    always @(*) begin
        if (!rst_n) begin
            s2_reg = 7'b0;
            c2_reg = 7'b0;
        end else begin
            s2_reg = s2;
            c2_reg = c2;
        end
    end
    
    // 第四级流水线：最终先行进位加法器(CLA)
    wire [7:0] final_sum;
    
    // 最终加法器 - 替换为先行进位加法器
    CLAAdder final_adder(
        .a({1'b0, s2_reg}),
        .b({c2_reg, 1'b0}),
        .product(final_sum)
    );
    
    // 输出寄存器
    always @(*) begin
        if (!rst_n) begin
            product = 8'b0;
        end else begin
            product = final_sum;
        end
    end
endmodule

module DaddaStage1(
    input [3:0] pp0, pp1, pp2, pp3,
    output [4:0] s1_1, c1_1,
    output [5:1] s1_2, c1_2
);
    // 初始化未使用的位
    assign s1_1[0] = 1'b0;
    assign s1_1[1] = 1'b0;
    assign c1_1[0] = 1'b0;
    assign c1_1[1] = 1'b0;
    
    // 半加器和全加器用于压缩部分积
    half_adder ha1_1(pp0[2], pp1[1], s1_1[2], c1_1[2]);
    full_adder fa1_1(pp0[3], pp1[2], pp2[1], s1_1[3], c1_1[3]);
    half_adder ha1_2(pp1[3], pp2[2], s1_1[4], c1_1[4]);
    
    // 初始化未使用的位
    assign s1_2[1] = 1'b0;
    assign s1_2[2] = 1'b0;
    assign s1_2[3] = 1'b0;
    assign s1_2[4] = 1'b0;
    assign c1_2[1] = 1'b0;
    assign c1_2[2] = 1'b0;
    assign c1_2[3] = 1'b0;
    assign c1_2[4] = 1'b0;
    
    half_adder ha1_3(pp2[3], pp3[2], s1_2[5], c1_2[5]);
endmodule

module DaddaStage2(
    input [3:0] pp0, pp1, pp2, pp3,
    input [4:0] s1_1, c1_1,
    input [5:1] s1_2, c1_2,
    output [6:0] s2, c2
);
    // 第二级压缩
    assign s2[0] = pp0[0];
    assign c2[0] = 1'b0;
    assign c2[6] = 1'b0;
    
    half_adder ha2_1(pp0[1], pp1[0], s2[1], c2[1]);
    full_adder fa2_1(s1_1[2], pp2[0], pp3[0], s2[2], c2[2]);
    full_adder fa2_2(s1_1[3], pp3[1], c1_1[2], s2[3], c2[3]);
    full_adder fa2_3(s1_1[4], s1_2[5], c1_1[3], s2[4], c2[4]);
    full_adder fa2_4(pp3[3], c1_1[4], c1_2[5], s2[5], c2[5]);
endmodule

module CLAAdder(
    input [7:0] a, b,
    output [7:0] product
);
    wire [7:0] p; // 生成位
    wire [7:0] g; // 传播位
    wire [7:0] c; // 进位信号
    
    // 计算生成位和传播位
    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin: pg_gen
            assign p[i] = a[i] ^ b[i]; // 传播位
            assign g[i] = a[i] & b[i]; // 生成位
        end
    endgenerate
    
    // 计算先行进位
    assign c[0] = 1'b0; // 初始无进位
    
    // 8位先行进位逻辑
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | 
                  (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 第二级分组
    wire [3:0] group_p, group_g;
    
    assign group_p[0] = p[3] & p[2] & p[1] & p[0];
    assign group_g[0] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[4]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c[4]);
    
    // 计算和
    generate
        for(i = 0; i < 7; i = i + 1) begin: sum_gen
            assign product[i] = p[i] ^ c[i];
        end
    endgenerate
    
    // 最高位特殊处理
    assign product[7] = p[7] ^ c[7];
endmodule

module half_adder(
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule