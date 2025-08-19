module AbsSub(
    input signed [7:0] x,
    input signed [7:0] y,
    output reg signed [7:0] res
);

    wire signed [7:0] neg_y;
    wire signed [7:0] neg_x;
    wire signed [7:0] sum1;
    wire signed [7:0] sum2;
    wire sel;

    // 计算补码
    assign neg_y = ~y + 1'b1;
    assign neg_x = ~x + 1'b1;
    
    // 使用Kogge-Stone加法器计算两种可能的差值
    KoggeStoneAdder ksa1(.a(x), .b(neg_y), .sum(sum1));
    KoggeStoneAdder ksa2(.a(y), .b(neg_x), .sum(sum2));
    
    // 选择较大的数
    assign sel = (x > y);
    
    // 根据选择信号输出结果
    always @(*) begin
        res = sel ? sum1 : sum2;
    end

endmodule

// Kogge-Stone加法器模块
module KoggeStoneAdder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
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
    wire [7:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[6] = p[6] & p[5];
    
    assign g1[7] = g[7] | (p[7] & g[6]);
    assign p1[7] = p[7] & p[6];
    
    // 第三级：计算进位
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];
    
    // 第四级：计算进位
    wire [7:0] g3, p3;
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign p3[6] = p2[6] & p2[2];
    
    assign g3[7] = g2[7] | (p2[7] & g2[3]);
    assign p3[7] = p2[7] & p2[3];
    
    // 计算最终进位
    assign carry[0] = 1'b0;
    assign carry[1] = g3[0];
    assign carry[2] = g3[1];
    assign carry[3] = g3[2];
    assign carry[4] = g3[3];
    assign carry[5] = g3[4];
    assign carry[6] = g3[5];
    assign carry[7] = g3[6];
    
    // 计算最终和
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
    assign sum[4] = p[4] ^ carry[4];
    assign sum[5] = p[5] ^ carry[5];
    assign sum[6] = p[6] ^ carry[6];
    assign sum[7] = p[7] ^ carry[7];

endmodule