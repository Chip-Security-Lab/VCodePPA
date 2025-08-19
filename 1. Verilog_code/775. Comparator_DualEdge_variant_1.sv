//SystemVerilog
module Comparator_DualEdge #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] x, y,
    output reg         neq
);
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] p, g;
    wire [WIDTH:0] carry;
    
    // 生成传播和生成信号
    assign p[0] = 1'b0;
    assign g[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_p_g
            assign p[i+1] = x[i] ^ (~y[i]);
            assign g[i+1] = x[i] & (~y[i]);
        end
    endgenerate
    
    // 并行前缀加法器计算进位
    assign carry[0] = 1'b0;
    
    // 第1级前缀运算
    wire [WIDTH:0] p_level1, g_level1;
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin: gen_level1
            if (i % 2 == 1 && i > 0) begin
                assign g_level1[i] = g[i] | (p[i] & g[i-1]);
                assign p_level1[i] = p[i] & p[i-1];
            end else begin
                assign g_level1[i] = g[i];
                assign p_level1[i] = p[i];
            end
        end
    endgenerate
    
    // 第2级前缀运算
    wire [WIDTH:0] p_level2, g_level2;
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin: gen_level2
            if (i % 4 == 3 && i > 0) begin
                assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
                assign p_level2[i] = p_level1[i] & p_level1[i-2];
            end else if (i % 4 == 2 && i > 0) begin
                assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-1]);
                assign p_level2[i] = p_level1[i] & p_level1[i-1];
            end else begin
                assign g_level2[i] = g_level1[i];
                assign p_level2[i] = p_level1[i];
            end
        end
    endgenerate
    
    // 第3级前缀运算
    wire [WIDTH:0] p_level3, g_level3;
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin: gen_level3
            if (i % 8 >= 4 && i > 0) begin
                assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
                assign p_level3[i] = p_level2[i] & p_level2[i-4];
            end else begin
                assign g_level3[i] = g_level2[i];
                assign p_level3[i] = p_level2[i];
            end
        end
    endgenerate
    
    // 计算所有位的进位
    generate
        for (i = 1; i <= WIDTH; i = i + 1) begin: gen_carry
            assign carry[i] = g_level3[i];
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_diff
            assign diff[i] = p[i+1] ^ carry[i];
        end
    endgenerate
    
    // 判断x和y是否相等
    wire is_diff;
    assign is_diff = |diff;
    
    // 同步输出结果
    always @(posedge clk) begin
        neq <= is_diff;
    end
endmodule