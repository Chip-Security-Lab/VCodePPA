module subtractor_overflow_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output overflow
);
    wire [7:0] b_comp;
    wire [7:0] sum;
    wire carry_out;
    wire a_sign, b_sign, sum_sign;
    
    // 计算b的补码
    assign b_comp = ~b + 1'b1;
    
    // 跳跃进位加法器实现
    wire [7:0] g, p;
    wire [7:0] c;
    
    // 生成和传播信号
    assign g = a & b_comp;
    assign p = a ^ b_comp;
    
    // 进位计算
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 最终和计算
    assign sum = p ^ c;
    assign carry_out = g[7] | (p[7] & c[7]);
    
    // 输出结果
    assign diff = sum;
    
    // 符号位提取
    assign a_sign = a[7];
    assign b_sign = b[7];
    assign sum_sign = sum[7];
    
    // 溢出检测逻辑
    assign overflow = (a_sign ^ sum_sign) & (a_sign ^ b_sign);
endmodule