//SystemVerilog
// 顶层模块
module Multiplier3(
    input clk,
    input [3:0] data_a, data_b,
    output [7:0] mul_result
);

    // 内部信号声明
    wire [3:0] data_a_buf, data_b_buf;
    wire [7:0] mult_out;
    wire [7:0] reg_out;

    // 输入缓冲寄存器
    InputBuffer u_input_buf(
        .clk(clk),
        .data_a_in(data_a),
        .data_b_in(data_b),
        .data_a_out(data_a_buf),
        .data_b_out(data_b_buf)
    );

    // 乘法运算子模块实例化
    MultiplierCore u_mult_core(
        .data_a(data_a_buf),
        .data_b(data_b_buf),
        .mult_result(mult_out)
    );

    // 寄存器子模块实例化
    ResultRegister u_result_reg(
        .clk(clk),
        .data_in(mult_out),
        .data_out(reg_out)
    );

    // 输出赋值
    assign mul_result = reg_out;

endmodule

// 输入缓冲寄存器子模块
module InputBuffer(
    input clk,
    input [3:0] data_a_in,
    input [3:0] data_b_in,
    output reg [3:0] data_a_out,
    output reg [3:0] data_b_out
);
    always @(posedge clk) begin
        data_a_out <= data_a_in;
        data_b_out <= data_b_in;
    end
endmodule

// 乘法运算核心子模块
module MultiplierCore(
    input [3:0] data_a,
    input [3:0] data_b,
    output [7:0] mult_result
);
    assign mult_result = data_a * data_b;
endmodule

// 结果寄存器子模块
module ResultRegister(
    input clk,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule