//SystemVerilog
// 顶层模块
module xor_iterative (
    input [3:0] x,
    input [3:0] y,
    output [3:0] z,
    output [3:0] sum,
    output cout
);
    // 直接实现XOR操作，无需子模块
    assign z = x ^ y;
    
    // 优化的并行前缀加法器
    wire [4:0] carry;
    
    // 初始进位为0
    assign carry[0] = 1'b0;
    
    // 简化的生成和传播信号
    wire [3:0] g, p;
    
    // 计算生成和传播信号
    assign g = x & y;   // 生成信号
    assign p = x ^ y;   // 传播信号 - 使用XOR代替OR提高精确性
    
    // 优化的并行前缀计算进位
    assign carry[1] = g[0];
    assign carry[2] = g[1] | (p[1] & g[0]);
    assign carry[3] = g[2] | (p[2] & (g[1] | (p[1] & g[0])));
    assign carry[4] = g[3] | (p[3] & (g[2] | (p[2] & (g[1] | (p[1] & g[0])))));
    
    // 计算最终和
    assign sum = p ^ {carry[3:0]};
    
    // 输出最终进位
    assign cout = carry[4];
endmodule