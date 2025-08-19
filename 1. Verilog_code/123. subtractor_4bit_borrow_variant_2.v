module subtractor_4bit_borrow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_comp;
    wire [3:0] g, p;
    wire [3:0] c;
    wire [3:0] sum;

    // 取反并加1实现补码
    assign b_comp = ~b;
    
    // 生成和传播信号
    assign g = a & b_comp;
    assign p = a ^ b_comp;
    
    // 进位计算优化
    assign c[0] = 1'b1;
    assign c[1] = g[0] | (p[0] & 1'b1);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & 1'b1);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & 1'b1);
    assign borrow = ~(g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & 1'b1));
    
    // 最终差
    assign sum = p ^ c;
    assign diff = sum;
endmodule