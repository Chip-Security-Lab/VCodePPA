//SystemVerilog
// 顶层模块
module TriState_AND(
    input oe_n,          // 低有效使能
    input [3:0] x, y,    // 输入数据
    output [3:0] z       // 输出数据
);
    // 内部连线
    wire [3:0] sub_result;
    
    // 实例化子模块
    Subtractor sub_op (
        .in1(x),
        .in2(y),
        .result(sub_result)
    );
    
    TriState_Buffer tri_buf (
        .oe_n(oe_n),
        .data_in(sub_result),
        .data_out(z)
    );
    
endmodule

// 二进制补码减法器子模块
module Subtractor #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] in1, in2,
    output [WIDTH-1:0] result
);
    // 实现二进制补码减法（in1 - in2）
    wire [WIDTH-1:0] in2_complement;
    wire carry;
    
    // 计算二进制补码：对in2取反加1
    assign in2_complement = ~in2 + 1'b1;
    
    // 执行加法：in1 + (二进制补码of in2)
    assign {carry, result} = in1 + in2_complement;
endmodule

// 三态缓冲器子模块
module TriState_Buffer #(
    parameter WIDTH = 4
)(
    input oe_n,                  // 低有效使能
    input [WIDTH-1:0] data_in,   // 输入数据
    output [WIDTH-1:0] data_out  // 三态输出
);
    // 当oe_n为低时输出数据，否则为高阻态
    assign data_out = (~oe_n) ? data_in : {WIDTH{1'bz}};
endmodule