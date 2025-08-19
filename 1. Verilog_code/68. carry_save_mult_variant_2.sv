//SystemVerilog
// 顶层模块
module carry_save_mult (
    input [3:0] A, B,
    output [7:0] Prod
);
    // 部分积生成模块实例化
    wire [3:0] pp0, pp1, pp2, pp3;
    partial_product_gen pp_gen (
        .A(A),
        .B(B),
        .pp0(pp0),
        .pp1(pp1), 
        .pp2(pp2),
        .pp3(pp3)
    );

    // Brent-Kung加法器模块实例化
    wire [7:0] sum;
    brent_kung_adder bk_adder (
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .sum(sum)
    );

    assign Prod = sum;
endmodule

// 部分积生成模块
module partial_product_gen (
    input [3:0] A, B,
    output [3:0] pp0, pp1, pp2, pp3
);
    assign pp0 = {4{B[0]}} & A;
    assign pp1 = {4{B[1]}} & A;
    assign pp2 = {4{B[2]}} & A;
    assign pp3 = {4{B[3]}} & A;
endmodule

// Brent-Kung加法器模块
module brent_kung_adder (
    input [3:0] pp0, pp1, pp2, pp3,
    output [7:0] sum
);
    // 生成和传播信号
    wire [7:0] g, p;
    wire [7:0] c;

    // 生成和传播信号计算
    assign g[0] = pp0[0];
    assign p[0] = 1'b0;
    
    assign g[1] = pp0[1] & pp1[0];
    assign p[1] = pp0[1] ^ pp1[0];
    
    assign g[2] = pp0[2] & pp1[1] & pp2[0];
    assign p[2] = pp0[2] ^ pp1[1] ^ pp2[0];
    
    assign g[3] = pp0[3] & pp1[2] & pp2[1] & pp3[0];
    assign p[3] = pp0[3] ^ pp1[2] ^ pp2[1] ^ pp3[0];
    
    assign g[4] = pp1[3] & pp2[2] & pp3[1];
    assign p[4] = pp1[3] ^ pp2[2] ^ pp3[1];
    
    assign g[5] = pp2[3] & pp3[2];
    assign p[5] = pp2[3] ^ pp3[2];
    
    assign g[6] = pp3[3];
    assign p[6] = 1'b0;
    
    assign g[7] = 1'b0;
    assign p[7] = 1'b0;

    // 进位计算
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]);

    // 最终和计算
    assign sum[0] = pp0[0];
    assign sum[1] = pp0[1] ^ pp1[0] ^ c[0];
    assign sum[2] = pp0[2] ^ pp1[1] ^ pp2[0] ^ c[1];
    assign sum[3] = pp0[3] ^ pp1[2] ^ pp2[1] ^ pp3[0] ^ c[2];
    assign sum[4] = pp1[3] ^ pp2[2] ^ pp3[1] ^ c[3];
    assign sum[5] = pp2[3] ^ pp3[2] ^ c[4];
    assign sum[6] = pp3[3] ^ c[5];
    assign sum[7] = c[6];
endmodule