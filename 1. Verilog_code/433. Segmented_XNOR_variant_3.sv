//SystemVerilog
module Segmented_XNOR(
    input  [7:0] high,
    input  [7:0] low,
    output [7:0] res
);
    wire [3:0] high_upper, high_lower;
    wire [3:0] low_upper, low_lower;
    wire [3:0] res_upper, res_lower;
    
    // 将输入信号分解为上半部和下半部
    Signal_Splitter high_splitter (
        .data_in(high),
        .upper_half(high_upper),
        .lower_half(high_lower)
    );
    
    Signal_Splitter low_splitter (
        .data_in(low),
        .upper_half(low_upper),
        .lower_half(low_lower)
    );
    
    // 执行XNOR操作
    XNOR_Unit upper_xnor (
        .a(high_upper),
        .b(low_lower),
        .result(res_upper)
    );
    
    XNOR_Unit lower_xnor (
        .a(high_lower),
        .b(low_upper),
        .result(res_lower)
    );
    
    // 将结果合并
    Signal_Merger result_merger (
        .upper_half(res_upper),
        .lower_half(res_lower),
        .data_out(res)
    );
    
endmodule

// 信号分割器模块 - 将8位输入分割为两个4位输出
module Signal_Splitter(
    input  [7:0] data_in,
    output [3:0] upper_half,
    output [3:0] lower_half
);
    assign upper_half = data_in[7:4];
    assign lower_half = data_in[3:0];
endmodule

// XNOR运算模块 - 执行4位XNOR操作
module XNOR_Unit(
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] result
);
    // 使用参数化设计以支持不同位宽
    assign result = a ~^ b;
endmodule

// 信号合并器模块 - 将两个4位输入合并为一个8位输出
module Signal_Merger(
    input  [3:0] upper_half,
    input  [3:0] lower_half,
    output [7:0] data_out
);
    assign data_out = {upper_half, lower_half};
endmodule