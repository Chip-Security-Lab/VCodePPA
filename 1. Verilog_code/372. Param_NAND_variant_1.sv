//SystemVerilog - IEEE 1364-2005
module Param_NAND #(parameter WIDTH=8) (
    input [WIDTH-1:0] x, y,
    output [WIDTH-1:0] z
);
    wire [WIDTH-1:0] y_complement;
    wire [WIDTH-1:0] sub_result;
    
    // 补码计算子模块实例
    TwosComplement #(.WIDTH(WIDTH)) twos_comp_inst (
        .data_in(y),
        .data_out(y_complement)
    );
    
    // 二进制加法子模块实例
    BinaryAdder #(.WIDTH(WIDTH)) adder_inst (
        .a(x),
        .b(y_complement),
        .sum(sub_result)
    );
    
    // 逻辑运算子模块实例
    LogicUnit #(.WIDTH(WIDTH)) logic_unit_inst (
        .a(x),
        .b(y),
        .z(z)
    );
endmodule

//二进制补码计算模块
module TwosComplement #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 对输入取反加1得到补码
    assign data_out = ~data_in + 1'b1;
endmodule

//二进制加法模块
module BinaryAdder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] sum
);
    // 执行二进制加法
    assign sum = a + b;
endmodule

//逻辑运算模块
module LogicUnit #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] z
);
    // 执行NAND逻辑运算
    assign z = ~(a & b);
endmodule