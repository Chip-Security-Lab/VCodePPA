//SystemVerilog
// 顶层模块 - 优化后的位操作扩展模块
module bit_ops_ext (
    input  wire        clk,    // 时钟信号
    input  wire        rst_n,  // 低电平复位
    input  wire [3:0]  src1,   // 源操作数1
    input  wire [3:0]  src2,   // 源操作数2
    output reg  [3:0]  concat, // 拼接结果
    output reg  [3:0]  reverse // 反转结果
);

    // 内部信号定义
    wire [3:0] concat_wire;
    wire [3:0] reverse_wire;
    
    // 拼接操作实例化
    concatenator #(
        .WIDTH(2)  // 参数化位宽
    ) concat_unit (
        .in1(src1[1:0]),
        .in2(src2[1:0]),
        .out(concat_wire)
    );

    // 位反转操作实例化
    bit_reverser #(
        .WIDTH(4)  // 参数化位宽
    ) reverse_unit (
        .in(src1),
        .out(reverse_wire)
    );

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            concat <= 4'b0;
            reverse <= 4'b0;
        end else begin
            concat <= concat_wire;
            reverse <= reverse_wire;
        end
    end

endmodule

// 参数化拼接器子模块
module concatenator #(
    parameter WIDTH = 2  // 默认位宽参数
)(
    input  wire [WIDTH-1:0] in1,  // 输入1
    input  wire [WIDTH-1:0] in2,  // 输入2
    output wire [2*WIDTH-1:0] out // 拼接输出
);

    // 参数化拼接实现
    assign out = {in1, in2};

endmodule

// 参数化位反转子模块
module bit_reverser #(
    parameter WIDTH = 4  // 默认位宽参数
)(
    input  wire [WIDTH-1:0] in,   // 输入
    output wire [WIDTH-1:0] out   // 反转输出
);

    // 参数化位反转实现
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : reverse_bit
            assign out[i] = in[WIDTH-1-i];
        end
    endgenerate

endmodule