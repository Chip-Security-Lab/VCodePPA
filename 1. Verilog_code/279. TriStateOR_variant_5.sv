//SystemVerilog
module TriStateOR(
    input oe,       // 输出使能
    input [7:0] a, b,
    output [7:0] y
);
    // 内部连线
    wire [7:0] or_result;
    
    // 实例化逻辑运算子模块
    LogicOperator logic_op (
        .a(a),
        .b(b),
        .result(or_result)
    );
    
    // 实例化三态输出控制子模块
    TriStateControl tri_ctrl (
        .oe(oe),
        .data_in(or_result),
        .data_out(y)
    );
endmodule

// 逻辑运算子模块 - 处理位运算操作
module LogicOperator(
    input [7:0] a, b,
    output [7:0] result
);
    // 参数化实现OR运算
    assign result = a | b;
endmodule

// 三态控制子模块 - 处理输出使能控制
module TriStateControl(
    input oe,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    always @(*) begin
        data_out = oe ? data_in : 8'bzzzzzzzz;
    end
endmodule