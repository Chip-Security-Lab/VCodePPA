//SystemVerilog
// Top module
module xor2_12 (
    input wire [3:0] A, B,
    output wire [3:0] Y
);
    wire [3:0] p, g; // 生成和传播信号
    wire [3:0] g_L1, p_L1; // 第一级生成和传播
    wire [3:0] g_L2, p_L2; // 第二级生成和传播
    wire [3:0] carry; // 进位信号
    wire cin = 1'b0; // 初始进位为0
    
    // 生成初始传播和生成信号
    assign p = A ^ B; // 传播信号
    assign g = A & B; // 生成信号
    
    // Kogge-Stone树形结构 - 第一级
    assign p_L1[0] = p[0];
    assign g_L1[0] = g[0];
    
    assign p_L1[1] = p[1] & p[0];
    assign g_L1[1] = g[1] | (p[1] & g[0]);
    
    assign p_L1[2] = p[2] & p[1];
    assign g_L1[2] = g[2] | (p[2] & g[1]);
    
    assign p_L1[3] = p[3] & p[2];
    assign g_L1[3] = g[3] | (p[3] & g[2]);
    
    // Kogge-Stone树形结构 - 第二级
    assign p_L2[0] = p_L1[0];
    assign g_L2[0] = g_L1[0];
    
    assign p_L2[1] = p_L1[1];
    assign g_L2[1] = g_L1[1];
    
    assign p_L2[2] = p_L1[2] & p_L1[0];
    assign g_L2[2] = g_L1[2] | (p_L1[2] & g_L1[0]);
    
    assign p_L2[3] = p_L1[3] & p_L1[1];
    assign g_L2[3] = g_L1[3] | (p_L1[3] & g_L1[1]);
    
    // 计算最终进位
    assign carry[0] = cin;
    assign carry[1] = g_L2[0];
    assign carry[2] = g_L2[1];
    assign carry[3] = g_L2[2];
    
    // 计算和
    assign Y = p ^ carry;
endmodule