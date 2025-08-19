//SystemVerilog
module Comparator_BitwiseXOR #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] vec_a,
    input  [WIDTH-1:0] vec_b,
    output             not_equal
);
    // 使用Brent-Kung加法器算法实现比较器
    
    wire [WIDTH-1:0] diff_vector;   // 存储异或结果
    
    // 第一级 - 计算差异向量
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : XOR_STAGE
            assign diff_vector[i] = vec_a[i] ^ vec_b[i];
        end
    endgenerate
    
    // Brent-Kung 并行前缀计算网络
    wire [WIDTH-1:0] prefix_or;  // 前缀或结果
    
    // 第一阶段：生成初始前缀
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : INIT_PREFIX
            assign prefix_or[i] = diff_vector[i];
        end
    endgenerate
    
    // 第二阶段：Brent-Kung并行前缀计算（对数级别）
    // 阶段1（步长=1）
    wire [WIDTH-1:0] level1;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : LEVEL1
            if (i % 2 == 1) begin
                assign level1[i] = prefix_or[i] | prefix_or[i-1];
            end else begin
                assign level1[i] = prefix_or[i];
            end
        end
    endgenerate
    
    // 阶段2（步长=2）
    wire [WIDTH-1:0] level2;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : LEVEL2
            if (i % 4 == 3) begin
                assign level2[i] = level1[i] | level1[i-2];
            end else begin
                assign level2[i] = level1[i];
            end
        end
    endgenerate
    
    // 阶段3（步长=4）
    wire [WIDTH-1:0] level3;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : LEVEL3
            if (i == 7) begin // 只有在8位宽度时才需要这一步
                assign level3[i] = level2[i] | level2[i-4];
            end else begin
                assign level3[i] = level2[i];
            end
        end
    endgenerate
    
    // 反向传播阶段
    wire [WIDTH-1:0] final_prefix;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : FINAL_PREFIX
            if (i == 0) begin
                assign final_prefix[i] = prefix_or[i];
            end else if (i == 1 || i == 3 || i == 5 || i == 7) begin
                assign final_prefix[i] = level3[i];
            end else if (i == 2 || i == 6) begin
                assign final_prefix[i] = level3[i] | final_prefix[i-1];
            end else if (i == 4) begin
                assign final_prefix[i] = level3[i] | final_prefix[i-1];
            end
        end
    endgenerate
    
    // 最终输出 - 任何位不同，则结果不相等
    assign not_equal = final_prefix[WIDTH-1];
endmodule