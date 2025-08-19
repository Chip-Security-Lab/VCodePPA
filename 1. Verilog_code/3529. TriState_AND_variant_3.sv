//SystemVerilog - IEEE 1364-2005
module TriState_AND(
    input oe_n,       // 低有效使能
    input [3:0] x, y,
    output [3:0] z
);
    // 内部信号声明
    wire [3:0] and_result;
    
    // 实例化功能子模块
    Bitwise_AND and_operation (
        .in1(x),
        .in2(y),
        .out(and_result)
    );
    
    Output_Buffer output_buffer (
        .enable_n(oe_n),
        .data_in(and_result),
        .data_out(z)
    );
endmodule

// 子模块：执行按位与操作
module Bitwise_AND(
    input [3:0] in1,
    input [3:0] in2,
    output [3:0] out
);
    assign out = in1 & in2;
endmodule

// 子模块：实现三态输出缓冲
module Output_Buffer(
    input enable_n,         // 低有效使能信号
    input [3:0] data_in,
    output [3:0] data_out
);
    // 实现三态逻辑，当enable_n为低时输出data_in，否则为高阻态
    assign data_out = {4{~enable_n}} & data_in;
endmodule