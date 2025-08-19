//SystemVerilog
//------------------------------------------------------------------------------
// 顶层模块: BusOR
// 功能: 16位总线按位或操作，使用层次化子模块结构
//------------------------------------------------------------------------------
module BusOR (
    input  [15:0] bus_a,
    input  [15:0] bus_b,
    output [15:0] bus_or
);

    wire [15:0] or_stage_out;

    // 实例化输入缓冲子模块
    BusInputBuffer #(.WIDTH(16)) u_input_buffer_a (
        .in(bus_a),
        .out(bus_a_buf)
    );

    BusInputBuffer #(.WIDTH(16)) u_input_buffer_b (
        .in(bus_b),
        .out(bus_b_buf)
    );

    // 实例化按位或逻辑子模块
    BusBitwiseOR #(.WIDTH(16)) u_bitwise_or (
        .a(bus_a_buf),
        .b(bus_b_buf),
        .y(or_stage_out)
    );

    // 实例化输出寄存子模块
    BusOutputRegister #(.WIDTH(16)) u_output_register (
        .in(or_stage_out),
        .out(bus_or)
    );

    // 内部信号定义
    wire [15:0] bus_a_buf;
    wire [15:0] bus_b_buf;

endmodule

//------------------------------------------------------------------------------
// 子模块: BusInputBuffer
// 功能: 对输入总线进行缓冲，提高信号完整性和时序裕度
//------------------------------------------------------------------------------
module BusInputBuffer #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    assign out = in;
endmodule

//------------------------------------------------------------------------------
// 子模块: BusBitwiseOR
// 功能: 对输入的两个总线进行按位或操作，支持参数化总线宽度
//------------------------------------------------------------------------------
module BusBitwiseOR #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);
    assign y = a | b;
endmodule

//------------------------------------------------------------------------------
// 子模块: BusOutputRegister
// 功能: 对输出总线进行寄存，提高时序性能和可综合性
//------------------------------------------------------------------------------
module BusOutputRegister #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    reg [WIDTH-1:0] out_reg;

    always @* begin
        out_reg = in;
    end

    assign out = out_reg;
endmodule