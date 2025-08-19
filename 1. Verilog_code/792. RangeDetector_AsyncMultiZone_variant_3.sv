//SystemVerilog
// 顶层模块 - 管理多区域检测系统
module RangeDetector_AsyncMultiZone #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bounds [ZONES*2-1:0],
    output [ZONES-1:0] zone_flags
);

    // 区域边界检测数据信号
    wire [WIDTH-1:0] zone_lower_bounds [ZONES-1:0];
    wire [WIDTH-1:0] zone_upper_bounds [ZONES-1:0];
    
    // 将输入边界分割为上下边界
    BoundsExtractor #(
        .ZONES(ZONES),
        .WIDTH(WIDTH)
    ) bounds_extractor_inst (
        .bounds_in(bounds),
        .lower_bounds(zone_lower_bounds),
        .upper_bounds(zone_upper_bounds)
    );
    
    // 实例化多个单区域检测器
    generate
        genvar i;
        for (i = 0; i < ZONES; i = i + 1) begin : zone_detector_inst
            SingleZoneDetector #(
                .WIDTH(WIDTH)
            ) detector (
                .data(data_in),
                .lower_bound(zone_lower_bounds[i]),
                .upper_bound(zone_upper_bounds[i]),
                .in_range(zone_flags[i])
            );
        end
    endgenerate

endmodule

// 边界提取模块 - 将一维边界数组转换为上下边界数组
module BoundsExtractor #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] bounds_in [ZONES*2-1:0],
    output [WIDTH-1:0] lower_bounds [ZONES-1:0],
    output [WIDTH-1:0] upper_bounds [ZONES-1:0]
);

    generate
        genvar i;
        for (i = 0; i < ZONES; i = i + 1) begin : bounds_assign
            assign lower_bounds[i] = bounds_in[2*i];     // 提取下边界
            assign upper_bounds[i] = bounds_in[2*i+1];   // 提取上边界
        end
    endgenerate

endmodule

// 单区域检测模块 - 检测输入数据是否在指定范围内
module SingleZoneDetector #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output in_range
);

    // 检测输入数据是否在指定的范围内
    // 如果 data >= lower_bound 且 data <= upper_bound，则 in_range = 1
    wire greater_equal, less_equal;
    
    // 使用流水线比较器以提高性能
    ComparisonUnit #(
        .WIDTH(WIDTH),
        .COMPARATOR_TYPE("GE")
    ) lower_comparator (
        .a(data),
        .b(lower_bound),
        .result(greater_equal)
    );
    
    ComparisonUnit #(
        .WIDTH(WIDTH),
        .COMPARATOR_TYPE("LE")
    ) upper_comparator (
        .a(data),
        .b(upper_bound),
        .result(less_equal)
    );

    // 只有当两个条件都满足时，输出才为1
    assign in_range = greater_equal & less_equal;

endmodule

// 通用比较器单元 - 可配置为大于等于或小于等于比较
module ComparisonUnit #(
    parameter WIDTH = 8,
    parameter COMPARATOR_TYPE = "GE"  // "GE" or "LE"
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output result
);

    generate
        if (COMPARATOR_TYPE == "GE") begin : ge_compare
            assign result = (a >= b);
        end
        else if (COMPARATOR_TYPE == "LE") begin : le_compare
            assign result = (a <= b);
        end
    endgenerate

endmodule