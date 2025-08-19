//SystemVerilog
//IEEE 1364-2005 Verilog
`timescale 1ns / 1ps

module diff_clk_buffer (
    input  wire single_ended_clk,
    output wire clk_p,
    output wire clk_n
);
    // 内部信号定义
    wire clk_buffered;
    
    // 实例化优化的输入缓冲和差分生成子模块
    input_buffer u_input_buffer (
        .clk_in  (single_ended_clk),
        .clk_out (clk_buffered)
    );
    
    diff_generator u_diff_generator (
        .clk_in  (clk_buffered),
        .clk_p   (clk_p),
        .clk_n   (clk_n)
    );
    
endmodule

//-------------------------------------------------------------------------------
// 输入缓冲模块：处理输入时钟信号的缓冲
//-------------------------------------------------------------------------------
module input_buffer (
    input  wire clk_in,
    output wire clk_out
);
    // 参数化缓冲延迟
    parameter BUFFER_DELAY = 0; // 单位: ps
    
    // 使用连续赋值替代延迟赋值，提高综合工具兼容性
    reg clk_buffered;
    
    always @(clk_in)
        clk_buffered = clk_in;
    
    assign clk_out = clk_buffered;
    
endmodule

//-------------------------------------------------------------------------------
// 差分信号生成模块：将单端信号转换为差分对
//-------------------------------------------------------------------------------
module diff_generator (
    input  wire clk_in,
    output wire clk_p,
    output wire clk_n
);
    // 参数化控制
    parameter SKEW_CONTROL = 0; // 单位: ps
    
    // 优化的差分信号生成逻辑
    reg p_signal, n_signal;
    
    always @(clk_in) begin
        p_signal = clk_in;
        n_signal = ~clk_in;
    end
    
    // 输出赋值
    assign clk_p = p_signal;
    assign clk_n = n_signal;
    
endmodule