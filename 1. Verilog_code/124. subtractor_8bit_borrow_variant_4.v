module subtractor_8bit_2comp (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);
    wire [7:0] b_comp;
    wire [8:0] sum;
    wire [1:0] g0, p0, g1, p1, g2, p2, g3, p3;
    wire [1:0] c1, c2, c3;
    
    // 计算b的补码
    assign b_comp = ~b + 1'b1;
    
    // 生成和传播信号
    assign g0 = a[1:0] & b_comp[1:0];
    assign p0 = a[1:0] ^ b_comp[1:0];
    assign g1 = a[3:2] & b_comp[3:2];
    assign p1 = a[3:2] ^ b_comp[3:2];
    assign g2 = a[5:4] & b_comp[5:4];
    assign p2 = a[5:4] ^ b_comp[5:4];
    assign g3 = a[7:6] & b_comp[7:6];
    assign p3 = a[7:6] ^ b_comp[7:6];
    
    // 进位计算
    assign c1 = g0 | (p0 & 1'b0);
    assign c2 = g1 | (p1 & c1);
    assign c3 = g2 | (p2 & c2);
    assign sum[8] = g3 | (p3 & c3);
    
    // 和计算
    assign sum[1:0] = p0;
    assign sum[3:2] = p1 ^ {c1, c1};
    assign sum[5:4] = p2 ^ {c2, c2};
    assign sum[7:6] = p3 ^ {c3, c3};
    
    assign diff = sum[7:0];
    assign borrow = sum[8];
endmodule