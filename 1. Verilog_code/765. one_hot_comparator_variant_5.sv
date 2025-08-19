//SystemVerilog
module one_hot_comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] one_hot_a,
    input [WIDTH-1:0] one_hot_b,
    output valid_one_hot_a,
    output valid_one_hot_b,
    output equal_states,
    output [WIDTH-1:0] common_states
);
    // 使用优先级编码器实现popcount
    wire [$clog2(WIDTH+1)-1:0] count_a, count_b;
    
    // 使用并行前缀网络计算popcount
    wire [WIDTH-1:0] sum_a, sum_b;
    wire [WIDTH-1:0] carry_a, carry_b;
    
    // 第一级：计算相邻位的和
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : first_stage
            assign sum_a[2*i] = one_hot_a[2*i] ^ one_hot_a[2*i+1];
            assign carry_a[2*i] = one_hot_a[2*i] & one_hot_a[2*i+1];
            
            assign sum_b[2*i] = one_hot_b[2*i] ^ one_hot_b[2*i+1];
            assign carry_b[2*i] = one_hot_b[2*i] & one_hot_b[2*i+1];
        end
    endgenerate
    
    // 第二级：合并结果
    wire [WIDTH/2-1:0] final_sum_a, final_sum_b;
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin : second_stage
            assign final_sum_a[i] = sum_a[4*i] ^ sum_a[4*i+2] ^ carry_a[4*i];
            assign final_sum_b[i] = sum_b[4*i] ^ sum_b[4*i+2] ^ carry_b[4*i];
        end
    endgenerate
    
    // 最终计数
    assign count_a = final_sum_a;
    assign count_b = final_sum_b;
    
    // 验证one-hot编码
    assign valid_one_hot_a = (count_a == 1);
    assign valid_one_hot_b = (count_b == 1);
    
    // 使用并行比较器优化相等性检查
    wire [WIDTH-1:0] bit_equals;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_comparison
            assign bit_equals[i] = one_hot_a[i] == one_hot_b[i];
        end
    endgenerate
    
    // 使用多级与门优化common_states计算
    wire [WIDTH/2-1:0] and_stage1;
    wire [WIDTH/4-1:0] and_stage2;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : and_stage1_gen
            assign and_stage1[i] = one_hot_a[2*i] & one_hot_b[2*i] | 
                                 one_hot_a[2*i+1] & one_hot_b[2*i+1];
        end
        for (i = 0; i < WIDTH/4; i = i + 1) begin : and_stage2_gen
            assign and_stage2[i] = and_stage1[2*i] | and_stage1[2*i+1];
        end
    endgenerate
    
    assign common_states = one_hot_a & one_hot_b;
    assign equal_states = &bit_equals | |and_stage2;
endmodule