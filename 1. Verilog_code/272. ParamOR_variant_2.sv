//SystemVerilog
module ParamOR #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] in1, in2,
    output logic [WIDTH-1:0] result
);
    // 实例化OR单元子模块
    BitWiseOR_Unit #(
        .WIDTH(WIDTH)
    ) or_unit_inst (
        .in1_vec(in1),
        .in2_vec(in2),
        .out_vec(result)
    );
endmodule

// 位级OR操作子模块
module BitWiseOR_Unit #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] in1_vec, in2_vec,
    output logic [WIDTH-1:0] out_vec
);
    // 优化实现：使用直接位级运算符替代循环结构，提高性能和减少资源消耗
    assign out_vec = in1_vec | in2_vec;
endmodule