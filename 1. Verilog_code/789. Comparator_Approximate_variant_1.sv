//SystemVerilog
module Comparator_Approximate #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3 // 最大允许差值
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output             approx_eq
);
    // 内部连线
    wire [WIDTH-1:0] diff;
    
    // 计算差值子模块实例化
    AbsoluteDifference #(
        .WIDTH(WIDTH)
    ) abs_diff_inst (
        .data_a(data_p),
        .data_b(data_q),
        .abs_diff(diff)
    );
    
    // 比较子模块实例化
    ThresholdComparator #(
        .WIDTH(WIDTH),
        .THRESHOLD(THRESHOLD)
    ) thresh_comp_inst (
        .diff_value(diff),
        .is_within_threshold(approx_eq)
    );
endmodule

module AbsoluteDifference #(
    parameter WIDTH = 10
)(
    input  [WIDTH-1:0] data_a,
    input  [WIDTH-1:0] data_b,
    output [WIDTH-1:0] abs_diff
);
    // 用参数化方式确定较大的值
    wire [WIDTH-1:0] larger  = (data_a > data_b) ? data_a : data_b;
    wire [WIDTH-1:0] smaller = (data_a > data_b) ? data_b : data_a;
    
    // 计算绝对差值
    assign abs_diff = larger - smaller;
endmodule

module ThresholdComparator #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3
)(
    input  [WIDTH-1:0] diff_value,
    output             is_within_threshold
);
    // 比较差值是否在阈值范围内
    assign is_within_threshold = (diff_value <= THRESHOLD);
endmodule