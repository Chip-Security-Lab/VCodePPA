//SystemVerilog
module Comparator_GrayCode #(
    parameter WIDTH = 4,
    parameter THRESHOLD = 1      // 允许差异位数
)(
    input  [WIDTH-1:0] gray_code_a,
    input  [WIDTH-1:0] gray_code_b,
    output             is_adjacent  
);
    // 格雷码差异检测
    wire [WIDTH-1:0] xor_result = gray_code_a ^ gray_code_b;
    
    // Kogge-Stone 并行前缀加法器实现汉明距离计算
    wire [WIDTH:0] pop_count;
    
    // 第一阶段: 生成和传播
    wire [WIDTH-1:0] gen_stage0;
    wire [WIDTH-1:0] prop_stage0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_prop_init
            assign gen_stage0[i] = xor_result[i];
            assign prop_stage0[i] = 0; // 由于是计数操作，没有进位传播
        end
    endgenerate
    
    // 第二阶段: 树形结构计算前缀和 (Kogge-Stone)
    wire [WIDTH-1:0] gen_stage1;
    wire [WIDTH-1:0] gen_stage2;
    
    // 阶段1: 距离为1的前缀操作
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: prefix_stage1
            if (i == 0)
                assign gen_stage1[i] = gen_stage0[i];
            else
                assign gen_stage1[i] = gen_stage0[i] + gen_stage0[i-1];
        end
    endgenerate
    
    // 阶段2: 距离为2的前缀操作
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: prefix_stage2
            if (i < 2)
                assign gen_stage2[i] = gen_stage1[i];
            else
                assign gen_stage2[i] = gen_stage1[i] + gen_stage1[i-2];
        end
    endgenerate
    
    // 汉明距离为位计数总和
    assign pop_count = gen_stage2[WIDTH-1];
    
    // 比较结果
    assign is_adjacent = (pop_count <= THRESHOLD);
endmodule