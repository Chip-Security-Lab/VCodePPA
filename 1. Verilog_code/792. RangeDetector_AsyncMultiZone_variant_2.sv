//SystemVerilog
// 顶层模块
module RangeDetector_AsyncMultiZone #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bounds [ZONES*2-1:0],
    output [ZONES-1:0] zone_flags
);
    // 分解成多个区域检测器实例
    genvar i;
    generate
        for(i=0; i<ZONES; i=i+1) begin : zone_detectors
            ZoneComparator #(
                .WIDTH(WIDTH)
            ) zone_comp (
                .data_in(data_in),
                .lower_bound(bounds[2*i]),
                .upper_bound(bounds[2*i+1]),
                .in_zone(zone_flags[i])
            );
        end
    endgenerate
endmodule

// 单区域比较器子模块
module ZoneComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output in_zone
);
    // 将比较逻辑分解为更小的子部分
    wire greater_equal, less_equal;
    
    // 下界比较器
    LowerBoundCheck #(
        .WIDTH(WIDTH)
    ) lower_check (
        .data(data_in),
        .bound(lower_bound),
        .is_valid(greater_equal)
    );
    
    // 上界比较器
    UpperBoundCheck #(
        .WIDTH(WIDTH)
    ) upper_check (
        .data(data_in),
        .bound(upper_bound),
        .is_valid(less_equal)
    );
    
    // 合并结果
    assign in_zone = greater_equal && less_equal;
endmodule

// 下界检查子模块
module LowerBoundCheck #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] bound,
    output is_valid
);
    assign is_valid = (data >= bound);
endmodule

// 上界检查子模块
module UpperBoundCheck #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] bound,
    output is_valid
);
    assign is_valid = (data <= bound);
endmodule