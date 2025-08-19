//SystemVerilog
// 顶层模块
module async_diff_filter #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_sample,
    input [DATA_SIZE-1:0] prev_sample,
    output [DATA_SIZE:0] diff_out  // One bit wider to handle negative
);
    // 扩展的输入信号
    wire [DATA_SIZE:0] extended_current;
    wire [DATA_SIZE:0] extended_prev;
    
    // 实例化信号扩展子模块
    sign_extension #(
        .IN_WIDTH(DATA_SIZE),
        .OUT_WIDTH(DATA_SIZE+1)
    ) current_extender (
        .data_in(current_sample),
        .data_out(extended_current)
    );
    
    sign_extension #(
        .IN_WIDTH(DATA_SIZE),
        .OUT_WIDTH(DATA_SIZE+1)
    ) prev_extender (
        .data_in(prev_sample),
        .data_out(extended_prev)
    );
    
    // 实例化差分计算子模块
    subtractor #(
        .WIDTH(DATA_SIZE+1)
    ) diff_calculator (
        .minuend(extended_current),
        .subtrahend(extended_prev),
        .difference(diff_out)
    );
endmodule

// 符号扩展子模块
module sign_extension #(
    parameter IN_WIDTH = 10,
    parameter OUT_WIDTH = 11
)(
    input [IN_WIDTH-1:0] data_in,
    output [OUT_WIDTH-1:0] data_out
);
    // 符号位扩展逻辑
    assign data_out = {{(OUT_WIDTH-IN_WIDTH){data_in[IN_WIDTH-1]}}, data_in};
endmodule

// 减法器子模块
module subtractor #(
    parameter WIDTH = 11
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // 高效减法实现
    assign difference = minuend - subtrahend;
endmodule