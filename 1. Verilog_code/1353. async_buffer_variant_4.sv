//SystemVerilog
module async_buffer (
    input wire clk,                // 时钟信号
    input wire rst_n,              // 低电平有效复位
    input wire [15:0] data_in,     // 输入数据
    input wire enable,             // 使能信号
    output reg [15:0] data_out     // 输出数据
);
    // 内部信号定义 - 建立流水线结构
    reg [15:0] data_stage1;        // 第一级流水线数据
    reg enable_stage1;             // 第一级流水线使能
    
    // 增加缓冲寄存器用于高扇出信号
    reg rst_n_buf1, rst_n_buf2;    // 复位信号缓冲器
    
    // 复位信号缓冲以减少扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_buf1 <= 1'b0;
            rst_n_buf2 <= 1'b0;
        end else begin
            rst_n_buf1 <= 1'b1;
            rst_n_buf2 <= 1'b1;
        end
    end
    
    // 第一级流水线 - 捕获输入，使用缓冲的复位信号
    always @(posedge clk or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            data_stage1 <= 16'b0;
            enable_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            enable_stage1 <= enable;
        end
    end
    
    // 第二级流水线 - 处理和输出，使用另一个缓冲的复位信号
    always @(posedge clk or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            data_out <= 16'b0;
        end else begin
            data_out <= enable_stage1 ? data_stage1 : 16'b0;
        end
    end
    
endmodule