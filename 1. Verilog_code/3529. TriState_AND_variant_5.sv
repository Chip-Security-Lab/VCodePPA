//SystemVerilog
// 顶层模块 - 集成所有子模块
module TriState_AND (
    input oe_n,         // 低有效使能
    input [3:0] x, y,   // 输入数据
    output [3:0] z      // 三态输出
);
    // 内部信号连接
    wire [3:0] and_result;
    
    // 子模块实例化
    AndOperation and_op (
        .x(x),
        .y(y),
        .result(and_result)
    );
    
    TriStateBuffer tri_buf (
        .oe_n(oe_n),
        .data_in(and_result),
        .data_out(z)
    );
endmodule

// 子模块：执行按位与逻辑运算
module AndOperation #(
    parameter WIDTH = 4
) (
    input [WIDTH-1:0] x,
    input [WIDTH-1:0] y,
    output [WIDTH-1:0] result
);
    // 并行执行所有位的与运算
    assign result = x & y;
endmodule

// 子模块：三态缓冲控制
module TriStateBuffer #(
    parameter WIDTH = 4
) (
    input oe_n,                // 低有效使能信号
    input [WIDTH-1:0] data_in, // 输入数据
    output [WIDTH-1:0] data_out // 三态输出
);
    // 实现三态缓冲逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : tri_buf_bits
            assign data_out[i] = oe_n ? 1'bz : data_in[i];
        end
    endgenerate
endmodule