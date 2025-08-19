module Comparator_Weighted #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT = 8'b1000_0001 // 位权重配置
)(
    input  [WIDTH-1:0] vector_a,
    input  [WIDTH-1:0] vector_b,
    output             a_gt_b
);
    // 加权和计算，使用模块级函数替代自动函数
    function integer weighted_sum;
        input [WIDTH-1:0] vec;
        integer i, sum;
        begin
            sum = 0;
            for (i=0; i<WIDTH; i=i+1) 
                sum = sum + (vec[i] * WEIGHT[i]);
            weighted_sum = sum;
        end
    endfunction

    // 使用连续赋值实现比较
    wire [31:0] sum_a, sum_b;
    assign sum_a = weighted_sum(vector_a);
    assign sum_b = weighted_sum(vector_b);
    assign a_gt_b = (sum_a > sum_b);
endmodule