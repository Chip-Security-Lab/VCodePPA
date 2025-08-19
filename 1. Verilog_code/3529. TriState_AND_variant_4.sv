//SystemVerilog
module TriState_AND(
    input oe_n, // 低有效使能
    input [3:0] x, y,
    output [3:0] z
);
    // 内部连线
    wire [3:0] and_result;
    
    // 子模块实例化
    AND_Operation and_op (
        .a(x),
        .b(y),
        .result(and_result)
    );
    
    OutputBuffer output_buf (
        .oe_n(oe_n),
        .data_in(and_result),
        .data_out(z)
    );
endmodule

// 逻辑计算子模块
module AND_Operation (
    input [3:0] a,
    input [3:0] b,
    output [3:0] result
);
    // 计算逻辑与
    assign result = a & b;
endmodule

// 输出控制子模块
module OutputBuffer (
    input oe_n,
    input [3:0] data_in,
    output [3:0] data_out
);
    // 三态输出控制
    assign data_out = (~oe_n) ? data_in : 4'bzzzz;
endmodule