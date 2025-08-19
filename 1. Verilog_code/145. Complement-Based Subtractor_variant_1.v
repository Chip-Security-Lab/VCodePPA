// 补码转换子模块
module complement_converter (
    input wire [7:0] input_data,
    output wire [7:0] complement_data
);
    assign complement_data = ~input_data + 1;
endmodule

// Kogge-Stone加法器子模块
module kogge_stone_adder (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);
    // 生成和传播信号
    wire [7:0] g, p;
    wire [7:0] carry;
    
    // 第一级：计算初始生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_initial
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // 第二级：计算进位
    wire [7:0] g_level1, p_level1;
    
    // 第0位进位
    assign carry[0] = g[0];
    
    // 第1位进位
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign carry[1] = g_level1[1];
    
    // 第2-3位进位
    wire [3:0] g_level2, p_level2;
    
    // 第2位进位
    assign g_level2[2] = g[2] | (p[2] & g[1]);
    assign p_level2[2] = p[2] & p[1];
    assign carry[2] = g_level2[2];
    
    // 第3位进位
    assign g_level2[3] = g[3] | (p[3] & g[2]);
    assign p_level2[3] = p[3] & p[2];
    assign carry[3] = g_level2[3];
    
    // 第4-7位进位
    wire [7:0] g_level3, p_level3;
    
    // 第4位进位
    assign g_level3[4] = g[4] | (p[4] & g[3]);
    assign p_level3[4] = p[4] & p[3];
    assign carry[4] = g_level3[4];
    
    // 第5位进位
    assign g_level3[5] = g[5] | (p[5] & g[4]);
    assign p_level3[5] = p[5] & p[4];
    assign carry[5] = g_level3[5];
    
    // 第6位进位
    assign g_level3[6] = g[6] | (p[6] & g[5]);
    assign p_level3[6] = p[6] & p[5];
    assign carry[6] = g_level3[6];
    
    // 第7位进位
    assign g_level3[7] = g[7] | (p[7] & g[6]);
    assign p_level3[7] = p[7] & p[6];
    assign carry[7] = g_level3[7];
    
    // 计算最终和
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ carry[0];
    assign sum[2] = p[2] ^ carry[1];
    assign sum[3] = p[3] ^ carry[2];
    assign sum[4] = p[4] ^ carry[3];
    assign sum[5] = p[5] ^ carry[4];
    assign sum[6] = p[6] ^ carry[5];
    assign sum[7] = p[7] ^ carry[6];
endmodule

// 顶层减法器模块
module subtractor_complement (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);
    wire [7:0] b_complement;
    
    // 实例化补码转换模块
    complement_converter comp_conv (
        .input_data(b),
        .complement_data(b_complement)
    );
    
    // 实例化Kogge-Stone加法器模块
    kogge_stone_adder add (
        .a(a),
        .b(b_complement),
        .sum(res)
    );
endmodule