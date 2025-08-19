//SystemVerilog
// 顶层模块
module range_detector_async(
    input wire [15:0] data_in,
    input wire [15:0] min_val, max_val,
    output wire within_range
);
    // 中间信号连接各个子模块
    wire above_min, below_max;
    
    // 实例化最小值比较器子模块
    min_comparator min_comp_inst (
        .data_in(data_in),
        .min_val(min_val),
        .above_min(above_min)
    );
    
    // 实例化最大值比较器子模块
    max_comparator max_comp_inst (
        .data_in(data_in),
        .max_val(max_val),
        .below_max(below_max)
    );
    
    // 实例化结果逻辑子模块
    result_logic result_logic_inst (
        .above_min(above_min),
        .below_max(below_max),
        .within_range(within_range)
    );
endmodule

// 最小值比较器子模块
module min_comparator #(
    parameter DATA_WIDTH = 16
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] min_val,
    output wire above_min
);
    // 检查输入是否大于等于最小值
    assign above_min = (data_in >= min_val);
endmodule

// 最大值比较器子模块
module max_comparator #(
    parameter DATA_WIDTH = 16
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] max_val,
    output wire below_max
);
    // 检查输入是否小于等于最大值
    assign below_max = (data_in <= max_val);
endmodule

// 结果逻辑子模块
module result_logic(
    input wire above_min,
    input wire below_max,
    output wire within_range
);
    // 组合输入信号确定最终结果
    assign within_range = above_min && below_max;
endmodule