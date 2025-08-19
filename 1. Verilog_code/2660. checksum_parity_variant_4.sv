//SystemVerilog
module checksum_parity (
    input [31:0] data, // 转换为打包数组 - 4个8位数据
    output reg parity_valid,
    output reg [7:0] checksum
);
    wire [7:0] data0 = data[7:0];
    wire [7:0] data1 = data[15:8];
    wire [7:0] data2 = data[23:16];
    wire [7:0] data3 = data[31:24];
    
    wire [7:0] sum_stage1_1, sum_stage1_2;
    wire [7:0] sum_final;
    
    // 第一阶段Brent-Kung加法器 - 并行计算两组加法
    brent_kung_adder_8bit adder1_stage1 (
        .a(data0),
        .b(data1),
        .sum(sum_stage1_1)
    );
    
    brent_kung_adder_8bit adder2_stage1 (
        .a(data2),
        .b(data3),
        .sum(sum_stage1_2)
    );
    
    // 第二阶段 - 合并第一阶段结果
    brent_kung_adder_8bit adder_stage2 (
        .a(sum_stage1_1),
        .b(sum_stage1_2),
        .sum(sum_final)
    );
    
    always @(*) begin
        checksum = sum_final;
        parity_valid = ^checksum;
    end
endmodule

// Brent-Kung加法器 8位模块
module brent_kung_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    // 生成(G)和传播(P)信号 - 预处理阶段
    wire [7:0] g, p;
    wire [7:0] carry;
    
    // 计算每一位的初始G和P
    assign g = a & b;       // 生成信号
    assign p = a ^ b;       // 传播信号
    
    // Brent-Kung前缀树结构
    // 第一级: 生成长度为2的组G和P
    wire [3:0] g_level1, p_level1;
    assign g_level1[0] = g[1] | (p[1] & g[0]);
    assign p_level1[0] = p[1] & p[0];
    assign g_level1[1] = g[3] | (p[3] & g[2]);
    assign p_level1[1] = p[3] & p[2];
    assign g_level1[2] = g[5] | (p[5] & g[4]);
    assign p_level1[2] = p[5] & p[4];
    assign g_level1[3] = g[7] | (p[7] & g[6]);
    assign p_level1[3] = p[7] & p[6];
    
    // 第二级: 生成长度为4的组G和P
    wire [1:0] g_level2, p_level2;
    assign g_level2[0] = g_level1[1] | (p_level1[1] & g_level1[0]);
    assign p_level2[0] = p_level1[1] & p_level1[0];
    assign g_level2[1] = g_level1[3] | (p_level1[3] & g_level1[2]);
    assign p_level2[1] = p_level1[3] & p_level1[2];
    
    // 第三级: 生成长度为8的组G
    wire g_level3;
    assign g_level3 = g_level2[1] | (p_level2[1] & g_level2[0]);
    
    // 计算每个位置的进位
    assign carry[0] = g[0];
    assign carry[1] = g_level1[0];
    assign carry[2] = g[2] | (p[2] & g_level1[0]);
    assign carry[3] = g_level2[0];
    assign carry[4] = g[4] | (p[4] & g_level2[0]);
    assign carry[5] = g_level1[2] | (p_level1[2] & g_level2[0]);
    assign carry[6] = g[6] | (p[6] & g_level1[2]) | (p[6] & p_level1[2] & g_level2[0]);
    assign carry[7] = g_level3;
    
    // 计算最终和 - 后处理阶段
    assign sum[0] = p[0];
    assign sum[7:1] = p[7:1] ^ carry[6:0];
endmodule