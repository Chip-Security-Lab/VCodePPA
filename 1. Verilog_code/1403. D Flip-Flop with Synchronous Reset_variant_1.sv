//SystemVerilog
module d_ff_sync_reset (
    input  wire clk,      // 系统时钟
    input  wire rst,      // 同步复位信号
    input  wire d,        // 数据输入
    output wire q         // 数据输出
);
    // 内部连接信号
    wire d_buffered;
    
    // 实例化输入缓冲子模块
    input_buffer input_stage (
        .clk(clk),
        .d_in(d),
        .d_out(d_buffered)
    );
    
    // 实例化主数据路径子模块
    data_path_with_reset main_stage (
        .clk(clk),
        .rst(rst),
        .d_in(d_buffered),
        .q_out(q)
    );
    
endmodule

// 输入缓冲子模块 - 提高输入路径的驱动能力
module input_buffer (
    input  wire clk,      // 系统时钟
    input  wire d_in,     // 原始数据输入
    output reg  d_out     // 缓冲后的数据输出
);
    // 输入缓冲逻辑
    always @(posedge clk) begin
        d_out <= d_in;
    end
endmodule

// 主数据路径子模块 - 包含同步复位逻辑
module data_path_with_reset (
    input  wire clk,      // 系统时钟
    input  wire rst,      // 同步复位信号
    input  wire d_in,     // 缓冲后的数据输入
    output reg  q_out     // 最终数据输出
);
    // 主数据路径逻辑与复位处理
    always @(posedge clk) begin
        if (rst)
            q_out <= 1'b0;
        else
            q_out <= d_in;
    end
endmodule