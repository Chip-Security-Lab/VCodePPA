//SystemVerilog
// 顶层模块 - 增强型D锁存器
module enhanced_d_latch #(
    parameter RESET_VAL = 1'b0      // 参数化复位值
)(
    input  wire clk,                // 时钟信号
    input  wire rst_n,              // 低电平有效的异步复位
    input  wire d,                  // 数据输入
    input  wire enable,             // 使能信号
    output wire q,                  // 正常输出
    output wire q_n                 // 互补输出
);
    // 内部信号声明
    wire control_en;
    wire data_out;
    
    // 实例化控制逻辑子模块
    latch_control_logic u_control (
        .enable     (enable),
        .clk        (clk),
        .control_en (control_en)
    );
    
    // 实例化数据通路子模块
    latch_datapath #(
        .RESET_VAL  (RESET_VAL)
    ) u_datapath (
        .d          (d),
        .control_en (control_en),
        .rst_n      (rst_n),
        .data_out   (data_out)
    );
    
    // 实例化输出缓冲子模块
    output_buffer u_outbuf (
        .data_in    (data_out),
        .q          (q),
        .q_n        (q_n)
    );
    
endmodule

// 控制逻辑子模块
module latch_control_logic (
    input  wire enable,
    input  wire clk,
    output wire control_en
);
    // 控制逻辑实现
    assign control_en = enable & clk;
    
endmodule

// 数据通路子模块
module latch_datapath #(
    parameter RESET_VAL = 1'b0
)(
    input  wire d,
    input  wire control_en,
    input  wire rst_n,
    output reg  data_out
);
    // 数据通路实现，带异步复位
    always @(control_en or d or rst_n) begin
        if (!rst_n)
            data_out <= RESET_VAL;
        else if (control_en)
            data_out <= d;
    end
    
endmodule

// 输出缓冲子模块
module output_buffer (
    input  wire data_in,
    output wire q,
    output wire q_n
);
    // 输出缓冲实现
    assign q = data_in;
    assign q_n = ~data_in;
    
endmodule