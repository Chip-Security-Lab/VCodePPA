//SystemVerilog
// 顶层模块
module d_ff_async_reset_top (
    input  wire clk,    // 时钟信号
    input  wire rst_n,  // 低电平有效的异步复位
    input  wire d,      // 数据输入
    output wire q       // 数据输出
);
    // 内部连线
    wire stage1_out;
    
    // 第一级流水线 - 输入寄存器模块
    input_stage input_reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .d_in   (d),
        .d_out  (stage1_out)
    );
    
    // 第二级流水线 - 输出寄存器模块
    output_stage output_reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .d_in   (stage1_out),
        .q      (q)
    );
endmodule

// 第一级流水线子模块
module input_stage #(
    parameter RESET_VALUE = 1'b0  // 可参数化的复位值
)(
    input  wire clk,    // 时钟信号
    input  wire rst_n,  // 低电平有效的异步复位
    input  wire d_in,   // 数据输入
    output reg  d_out   // 数据输出到下一级
);
    // 输入寄存器逻辑 - 使用条件运算符替代if-else
    always @(posedge clk or negedge rst_n) begin
        d_out <= (!rst_n) ? RESET_VALUE : d_in;
    end
endmodule

// 第二级流水线子模块
module output_stage #(
    parameter RESET_VALUE = 1'b0  // 可参数化的复位值
)(
    input  wire clk,    // 时钟信号
    input  wire rst_n,  // 低电平有效的异步复位
    input  wire d_in,   // 来自前一级的数据
    output reg  q       // 最终输出
);
    // 输出寄存器逻辑 - 使用条件运算符替代if-else
    always @(posedge clk or negedge rst_n) begin
        q <= (!rst_n) ? RESET_VALUE : d_in;
    end
endmodule