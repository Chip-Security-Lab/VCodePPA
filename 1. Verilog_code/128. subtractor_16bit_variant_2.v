module subtractor_16bit (
    input [15:0] a,
    input [15:0] b,
    output [15:0] diff
);

    wire [15:0] b_comp;    // b的补码
    wire [15:0] b_neg;     // b的负数形式
    wire [15:0] sum;       // 加法结果
    wire carry;            // 进位信号

    // 计算b的补码
    assign b_comp = ~b + 1'b1;
    
    // Kogge-Stone加法器实现
    wire [15:0] p, g;      // 传播和生成信号
    wire [15:0] p_stage1, g_stage1;
    wire [15:0] p_stage2, g_stage2;
    wire [15:0] p_stage3, g_stage3;
    wire [15:0] p_stage4, g_stage4;
    wire [15:0] carry_out;

    // 预计算p和g
    assign p = a ^ b_comp;
    assign g = a & b_comp;

    // 第一级前缀计算
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin
            assign p_stage1[i] = p[i] & p[i-1];
            assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate

    // 第二级前缀计算
    assign p_stage2[1:0] = p_stage1[1:0];
    assign g_stage2[1:0] = g_stage1[1:0];
    generate
        for (i = 2; i < 16; i = i + 1) begin
            assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
            assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
        end
    endgenerate

    // 第三级前缀计算
    assign p_stage3[3:0] = p_stage2[3:0];
    assign g_stage3[3:0] = g_stage2[3:0];
    generate
        for (i = 4; i < 16; i = i + 1) begin
            assign p_stage3[i] = p_stage2[i] & p_stage2[i-4];
            assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-4]);
        end
    endgenerate

    // 第四级前缀计算
    assign p_stage4[7:0] = p_stage3[7:0];
    assign g_stage4[7:0] = g_stage3[7:0];
    generate
        for (i = 8; i < 16; i = i + 1) begin
            assign p_stage4[i] = p_stage3[i] & p_stage3[i-8];
            assign g_stage4[i] = g_stage3[i] | (p_stage3[i] & g_stage3[i-8]);
        end
    endgenerate

    // 计算进位
    assign carry_out[0] = g[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin
            assign carry_out[i] = g_stage4[i];
        end
    endgenerate

    // 计算最终和
    assign sum[0] = p[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin
            assign sum[i] = p[i] ^ carry_out[i-1];
        end
    endgenerate

    // 输出结果
    assign diff = sum;

endmodule