//SystemVerilog
// 顶层模块 - 同步复位解码器
module sync_rst_decoder (
    input                clk,      // 系统时钟
    input                rst,      // 同步复位信号
    input        [3:0]   addr,     // 地址输入
    output       [15:0]  select    // 解码输出
);
    // 内部连接信号
    wire [15:0] decoder_output;
    
    // 实例化第一级流水线：解码模块
    one_hot_decoder decoder_stage (
        .clk           (clk),
        .rst           (rst),
        .addr          (addr),
        .decoder_out   (decoder_output)
    );
    
    // 实例化第二级流水线：输出寄存器模块
    output_register output_stage (
        .clk           (clk),
        .rst           (rst),
        .data_in       (decoder_output),
        .data_out      (select)
    );
    
endmodule

// 子模块1：一热码解码器
module one_hot_decoder (
    input               clk,         // 系统时钟
    input               rst,         // 同步复位信号
    input        [3:0]  addr,        // 地址输入
    output reg   [15:0] decoder_out  // 解码输出
);
    // 解码地址生成一热码
    always @(posedge clk) begin
        if (rst)
            decoder_out <= 16'b0;
        else
            decoder_out <= (16'b1 << addr);
    end
endmodule

// 子模块2：输出寄存器
module output_register (
    input               clk,         // 系统时钟
    input               rst,         // 同步复位信号
    input        [15:0] data_in,     // 数据输入
    output reg   [15:0] data_out     // 数据输出
);
    // 输出寄存器逻辑
    always @(posedge clk) begin
        if (rst)
            data_out <= 16'b0;
        else
            data_out <= data_in;
    end
endmodule