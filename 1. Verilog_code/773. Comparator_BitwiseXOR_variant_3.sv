//SystemVerilog
module Comparator_CLA #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] vec_a,
    input  [WIDTH-1:0] vec_b,
    output             not_equal
);
    // 使用先行进位加法器原理优化比较器
    // 定义生成(G)和传播(P)信号
    wire [WIDTH-1:0] G, P;
    wire [WIDTH:0] C;  // 进位信号，额外一位用于最终结果
    
    // 初始化进位为0
    assign C[0] = 1'b0;
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_GP
            assign G[i] = vec_a[i] & vec_b[i];  // 生成信号
            assign P[i] = vec_a[i] | vec_b[i];  // 传播信号
        end
    endgenerate
    
    // 先行进位逻辑 - 2位分组
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : CLA_2BIT
            if (i+1 < WIDTH) begin
                // 2位CLA单元
                assign C[i+1] = G[i] | (P[i] & C[i]);
                assign C[i+2] = G[i+1] | (P[i+1] & C[i+1]);
            end else if (i < WIDTH) begin
                // 处理奇数位宽情况
                assign C[i+1] = G[i] | (P[i] & C[i]);
            end
        end
    endgenerate
    
    // 使用异或操作检测vec_a和vec_b之间的差异
    wire [WIDTH-1:0] diff_bits;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_DIFF
            assign diff_bits[i] = vec_a[i] ^ vec_b[i];
        end
    endgenerate
    
    // 使用先行进位网络快速计算是否有任何差异
    wire [3:0] diff_group;
    
    // 分组归约
    assign diff_group[0] = |diff_bits[1:0];
    assign diff_group[1] = |diff_bits[3:2];
    assign diff_group[2] = |diff_bits[5:4];
    assign diff_group[3] = |diff_bits[7:6];
    
    // 最终比较结果 - 使用CLA的C[WIDTH]作为校验
    wire cla_result = C[WIDTH] ^ C[0];
    wire direct_result = |diff_group;
    
    // 组合两种方法提高可靠性和性能
    assign not_equal = direct_result | cla_result;
    
endmodule