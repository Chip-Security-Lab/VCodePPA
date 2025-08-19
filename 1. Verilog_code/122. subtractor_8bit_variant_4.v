module subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);

    // 使用Kogge-Stone并行前缀结构优化
    wire [7:0] p, g;
    wire [7:0] b_comp = ~b;
    
    // 生成传播和生成信号
    assign p = a ^ b_comp;
    assign g = a & b_comp;

    // 并行前缀计算 - 优化结构
    wire [7:0] p_1, g_1;
    wire [7:0] p_2, g_2;
    wire [7:0] p_3, g_3;
    
    // 第一级 - 使用查找表优化
    assign p_1[0] = p[0];
    assign g_1[0] = g[0];
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin
            // 使用组合逻辑优化
            assign p_1[i] = p[i] & p[i-1];
            assign g_1[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate

    // 第二级 - 使用树形结构优化
    assign p_2[0] = p_1[0];
    assign g_2[0] = g_1[0];
    assign p_2[1] = p_1[1];
    assign g_2[1] = g_1[1];
    generate
        for (i = 2; i < 8; i = i + 1) begin
            // 使用组合逻辑优化
            assign p_2[i] = p_1[i] & p_1[i-2];
            assign g_2[i] = g_1[i] | (p_1[i] & g_1[i-2]);
        end
    endgenerate

    // 第三级 - 使用树形结构优化
    assign p_3[0] = p_2[0];
    assign g_3[0] = g_2[0];
    assign p_3[1] = p_2[1];
    assign g_3[1] = g_2[1];
    assign p_3[2] = p_2[2];
    assign g_3[2] = g_2[2];
    assign p_3[3] = p_2[3];
    assign g_3[3] = g_2[3];
    generate
        for (i = 4; i < 8; i = i + 1) begin
            // 使用组合逻辑优化
            assign p_3[i] = p_2[i] & p_2[i-4];
            assign g_3[i] = g_2[i] | (p_2[i] & g_2[i-4]);
        end
    endgenerate

    // 最终和计算 - 使用组合逻辑优化
    wire [7:0] carry;
    assign carry[0] = 1'b1;  // 减法初始进位
    assign carry[7:1] = g_3[6:0];
    
    // 使用异或门优化
    assign diff = p ^ carry;

endmodule