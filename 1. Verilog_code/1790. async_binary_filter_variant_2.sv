//SystemVerilog
// 顶层模块
module async_binary_filter #(
    parameter W = 8
)(
    input [W-1:0] analog_in,
    input [W-1:0] threshold,
    output binary_out
);
    // 内部连线
    wire comparison_result;
    
    // 子模块实例化
    threshold_comparator #(
        .DATA_WIDTH(W)
    ) comp_inst (
        .signal_input(analog_in),
        .threshold_value(threshold),
        .comparison_result(comparison_result)
    );
    
    output_generator out_gen_inst (
        .comparison_in(comparison_result),
        .binary_output(binary_out)
    );
endmodule

// 阈值比较器子模块
module threshold_comparator #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] signal_input,
    input [DATA_WIDTH-1:0] threshold_value,
    output comparison_result
);
    // 使用带符号比较以提高某些FPGA架构上的性能
    assign comparison_result = ($signed(signal_input) >= $signed(threshold_value));
endmodule

// 输出生成器子模块
module output_generator (
    input comparison_in,
    output binary_output
);
    // 添加缓冲以改善驱动能力和时序特性
    assign binary_output = comparison_in;
endmodule