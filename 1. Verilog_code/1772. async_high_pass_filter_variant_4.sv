//SystemVerilog
module async_high_pass_filter #(
    parameter DATA_WIDTH = 10
)(
    input [DATA_WIDTH-1:0] signal_input,
    input [DATA_WIDTH-1:0] avg_input,  // Moving average input
    output [DATA_WIDTH-1:0] filtered_out
);
    // 实例化减法器子模块
    subtractor #(
        .WIDTH(DATA_WIDTH)
    ) subtractor_inst (
        .a(signal_input),
        .b(avg_input),
        .result(filtered_out)
    );
endmodule

// 通用减法器模块
module subtractor #(
    parameter WIDTH = 10
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // 高效减法实现
    assign result = a - b;
endmodule