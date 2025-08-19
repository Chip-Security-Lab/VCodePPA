//SystemVerilog
module Comparator_Weighted #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT = 8'b1000_0001 // 位权重配置
)(
    input  [WIDTH-1:0] vector_a,
    input  [WIDTH-1:0] vector_b,
    output             a_gt_b
);
    // 连接信号
    wire [31:0] sum_a, sum_b;
    
    // 实例化权重求和子模块
    WeightedSumCalculator #(
        .WIDTH(WIDTH),
        .WEIGHT(WEIGHT)
    ) sum_calculator_a (
        .vector(vector_a),
        .weighted_sum(sum_a)
    );
    
    WeightedSumCalculator #(
        .WIDTH(WIDTH),
        .WEIGHT(WEIGHT)
    ) sum_calculator_b (
        .vector(vector_b),
        .weighted_sum(sum_b)
    );
    
    // 实例化比较器子模块
    SumComparator sum_comparator (
        .sum_a(sum_a),
        .sum_b(sum_b),
        .a_gt_b(a_gt_b)
    );
endmodule

// 权重求和计算子模块
module WeightedSumCalculator #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT = 8'b1000_0001
)(
    input  [WIDTH-1:0] vector,
    output [31:0]      weighted_sum
);
    // 局部变量
    reg [31:0] sum;
    integer i;
    
    // 使用组合逻辑计算加权和
    always @(*) begin
        sum = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (vector[i]) begin
                sum = sum + WEIGHT[i];
            end
        end
    end
    
    // 输出赋值
    assign weighted_sum = sum;
endmodule

// 比较器子模块
module SumComparator (
    input  [31:0] sum_a,
    input  [31:0] sum_b,
    output        a_gt_b
);
    // 简单比较逻辑
    assign a_gt_b = (sum_a > sum_b);
endmodule