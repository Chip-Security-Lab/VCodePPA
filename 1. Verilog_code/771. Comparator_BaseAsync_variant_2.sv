//SystemVerilog
// 顶层比较器模块，将比较逻辑分解为更小的功能子模块
module Comparator_BaseAsync #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_a,    // 输入数据A
    input  [WIDTH-1:0] data_b,    // 输入数据B
    output             o_equal    // 等于比较结果
);
    // 分段比较信号
    wire [1:0] segment_equal;
    
    // 实例化比较子模块，分段处理提高PPA
    ComparatorSegment #(
        .WIDTH(WIDTH/2)
    ) lower_segment_compare (
        .segment_a(data_a[WIDTH/2-1:0]),
        .segment_b(data_b[WIDTH/2-1:0]),
        .equal(segment_equal[0])
    );
    
    ComparatorSegment #(
        .WIDTH(WIDTH - WIDTH/2)
    ) upper_segment_compare (
        .segment_a(data_a[WIDTH-1:WIDTH/2]),
        .segment_b(data_b[WIDTH-1:WIDTH/2]),
        .equal(segment_equal[1])
    );
    
    // 结果合并模块
    ResultCombiner result_merge (
        .segment_results(segment_equal),
        .final_result(o_equal)
    );
    
endmodule

// 比较子模块 - 处理部分数据段的比较
module ComparatorSegment #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] segment_a,  // 数据段A
    input  [WIDTH-1:0] segment_b,  // 数据段B
    output reg         equal       // 段比较结果
);
    // 纯组合逻辑实现段比较
    always @(*) begin
        equal = (segment_a == segment_b);
    end
endmodule

// 结果合并子模块 - 将多个段比较结果合并为最终结果
module ResultCombiner (
    input  [1:0] segment_results,  // 各段比较结果
    output       final_result      // 最终合并结果
);
    // 所有段必须相等才能输出相等结果
    assign final_result = &segment_results;
endmodule