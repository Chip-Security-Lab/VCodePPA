module Sub5(
    input [3:0] A,
    input [3:0] B,
    output [3:0] D,
    output Bout
);

    wire [3:0] neg_B;
    wire [4:0] g, p;
    wire [4:0] c;
    
    // 取反操作
    assign neg_B = ~B;
    
    // 生成和传播信号
    assign g[0] = A[0] & neg_B[0];
    assign p[0] = A[0] ^ neg_B[0];
    assign g[1] = A[1] & neg_B[1];
    assign p[1] = A[1] ^ neg_B[1];
    assign g[2] = A[2] & neg_B[2];
    assign p[2] = A[2] ^ neg_B[2];
    assign g[3] = A[3] & neg_B[3];
    assign p[3] = A[3] ^ neg_B[3];
    
    // 进位计算
    assign c[0] = 1'b1;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 和计算
    assign D[0] = p[0] ^ c[0];
    assign D[1] = p[1] ^ c[1];
    assign D[2] = p[2] ^ c[2];
    assign D[3] = p[3] ^ c[3];
    
    assign Bout = c[4];

endmodule