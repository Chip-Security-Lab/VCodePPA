//SystemVerilog
// 顶层模块
module TriStateOR(
    input oe,       // 输出使能
    input [7:0] a, b,
    output [7:0] y
);
    // 内部连线
    wire [7:0] or_result;
    
    // 实例化逻辑运算子模块
    LogicOperation #(
        .WIDTH(8)
    ) logic_op_inst (
        .a(a),
        .b(b),
        .result(or_result)
    );
    
    // 实例化三态输出缓冲器子模块
    TriStateBuffer #(
        .WIDTH(8)
    ) tri_buf_inst (
        .oe(oe),
        .data_in(or_result),
        .data_out(y)
    );
endmodule

// 逻辑运算子模块 - 执行OR操作
module LogicOperation #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] result
);
    // 执行参数化宽度的OR操作
    assign result = a | b;
endmodule

// 三态输出缓冲器子模块
module TriStateBuffer #(
    parameter WIDTH = 8
)(
    input oe,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 基于输出使能的三态输出控制
    assign data_out = oe ? data_in : {WIDTH{1'bz}};
endmodule