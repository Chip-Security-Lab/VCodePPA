//SystemVerilog
module Comparator_Weighted #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT = 8'b1000_0001 // 位权重配置
)(
    input  [WIDTH-1:0] vector_a,
    input  [WIDTH-1:0] vector_b,
    output             a_gt_b
);
    // 计算加权和
    wire [31:0] sum_a, sum_b;
    
    // 使用先行进位加法器计算加权和
    CLA_Weighted_Sum #(.WIDTH(WIDTH)) cla_sum_a (
        .vec(vector_a),
        .weight(WEIGHT),
        .sum(sum_a)
    );
    
    CLA_Weighted_Sum #(.WIDTH(WIDTH)) cla_sum_b (
        .vec(vector_b),
        .weight(WEIGHT),
        .sum(sum_b)
    );
    
    // 比较结果
    assign a_gt_b = (sum_a > sum_b);
endmodule

// 使用先行进位加法器的加权和计算模块
module CLA_Weighted_Sum #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] vec,
    input [WIDTH-1:0] weight,
    output [31:0] sum
);
    // 初始积
    wire [31:0] products [WIDTH-1:0];
    
    // 计算各位与权重的乘积
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_products
            assign products[i] = vec[i] ? {{(32-i){1'b0}}, weight[i], {i{1'b0}}} : 32'b0;
        end
    endgenerate
    
    // 使用先行进位加法器累加所有乘积
    wire [31:0] partial_sums [WIDTH:0];
    wire [WIDTH:0] carry_gen, carry_prop;
    wire [WIDTH:0] carry;
    
    assign partial_sums[0] = 32'b0;
    assign carry[0] = 1'b0; // 初始进位为0
    
    // 计算生成(G)和传播(P)信号
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            wire [31:0] temp_sum = partial_sums[i] ^ products[i];
            wire [31:0] temp_carry = partial_sums[i] & products[i];
            
            assign carry_gen[i+1] = |temp_carry;
            assign carry_prop[i+1] = |temp_sum;
            
            // 计算进位
            assign carry[i+1] = carry_gen[i+1] | (carry_prop[i+1] & carry[i]);
            
            // 计算部分和
            wire [31:0] stage_sum = temp_sum;
            wire [31:0] stage_carry = {temp_carry[30:0], carry[i]};
            
            // 先行进位加法
            assign partial_sums[i+1] = stage_sum ^ stage_carry;
        end
    endgenerate
    
    // 最终结果
    assign sum = partial_sums[WIDTH];
endmodule