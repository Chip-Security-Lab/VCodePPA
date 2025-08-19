//SystemVerilog
// 顶层模块
module approximate_comparator #(
    parameter WIDTH = 12,
    parameter TOLERANCE = 3
)(
    input [WIDTH-1:0] value_a,
    input [WIDTH-1:0] value_b,
    input [WIDTH-1:0] custom_tolerance,
    input use_custom_tolerance,
    output approximate_match
);

    wire [WIDTH-1:0] effective_tolerance;
    wire [WIDTH-1:0] difference;

    // 实例化子模块
    tolerance_selector #(
        .WIDTH(WIDTH)
    ) tolerance_sel (
        .custom_tolerance(custom_tolerance),
        .use_custom_tolerance(use_custom_tolerance),
        .default_tolerance(TOLERANCE),
        .effective_tolerance(effective_tolerance)
    );

    difference_calculator #(
        .WIDTH(WIDTH)
    ) diff_calc (
        .value_a(value_a),
        .value_b(value_b),
        .difference(difference)
    );

    comparator #(
        .WIDTH(WIDTH)
    ) comp (
        .difference(difference),
        .tolerance(effective_tolerance),
        .match(approximate_match)
    );

endmodule

// 容差选择子模块
module tolerance_selector #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] custom_tolerance,
    input use_custom_tolerance,
    input [WIDTH-1:0] default_tolerance,
    output [WIDTH-1:0] effective_tolerance
);

    assign effective_tolerance = use_custom_tolerance ? custom_tolerance : default_tolerance;

endmodule

// 差值计算子模块
module difference_calculator #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] value_a,
    input [WIDTH-1:0] value_b,
    output [WIDTH-1:0] difference
);

    assign difference = (value_a > value_b) ? (value_a - value_b) : (value_b - value_a);

endmodule

// 比较器子模块
module comparator #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] difference,
    input [WIDTH-1:0] tolerance,
    output match
);

    assign match = (difference <= tolerance);

endmodule