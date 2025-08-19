module Sub1(input [7:0] a, b, output [7:0] result);
    wire [7:0] b_comp;
    wire [7:0] g, p;
    wire [7:0] carry;
    
    // 计算补码
    assign b_comp = ~b + 1'b1;
    
    // 生成和传播信号
    assign g = a & b_comp;
    assign p = a ^ b_comp;
    
    // 优化的并行前缀进位计算
    wire [7:0] p_prod;
    assign p_prod[0] = p[0];
    assign p_prod[1] = p[1] & p[0];
    assign p_prod[2] = p[2] & p[1] & p[0];
    assign p_prod[3] = p[3] & p[2] & p[1] & p[0];
    assign p_prod[4] = p[4] & p[3] & p[2] & p[1] & p[0];
    assign p_prod[5] = p[5] & p[4] & p[3] & p[2] & p[1] & p[0];
    assign p_prod[6] = p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0];
    assign p_prod[7] = p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0];
    
    // 优化的进位计算
    assign carry[0] = g[0];
    assign carry[1] = g[1] | (p[1] & carry[0]);
    assign carry[2] = g[2] | (p[2] & carry[1]);
    assign carry[3] = g[3] | (p[3] & carry[2]);
    assign carry[4] = g[4] | (p[4] & carry[3]);
    assign carry[5] = g[5] | (p[5] & carry[4]);
    assign carry[6] = g[6] | (p[6] & carry[5]);
    assign carry[7] = g[7] | (p[7] & carry[6]);
    
    // 计算最终结果
    assign result = p ^ {carry[6:0], 1'b0};
endmodule