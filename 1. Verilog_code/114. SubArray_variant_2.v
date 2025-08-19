// 二进制补码计算子模块
module BinaryComplement(
    input [3:0] in,
    output [3:0] out
);
    // 计算二进制补码: 取反加1
    assign out = ~in + 1'b1;
endmodule

// 加法器子模块
module Adder(
    input [3:0] a,
    input [3:0] b,
    output [3:0] sum
);
    // 执行加法运算
    assign sum = a + b;
endmodule

// 顶层减法器模块
module SubArray(
    input [3:0] a,
    input [3:0] b,
    output [3:0] d
);
    // 内部信号
    wire [3:0] b_comp;
    
    // 实例化二进制补码计算模块
    BinaryComplement comp_unit(
        .in(b),
        .out(b_comp)
    );
    
    // 实例化加法器模块
    Adder add_unit(
        .a(a),
        .b(b_comp),
        .sum(d)
    );
endmodule