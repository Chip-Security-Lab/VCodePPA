//SystemVerilog
module dual_d_flip_flop (
    input  wire clk,    // 系统时钟
    input  wire rst_n,  // 低电平有效复位信号
    input  wire d1,     // 数据输入1
    input  wire d2,     // 数据输入2
    input  wire b0,     // 高扇出控制信号
    output reg  q1,     // 寄存器输出1
    output reg  q2      // 寄存器输出2
);
    // 内部数据流分段寄存器
    reg d1_stage;
    reg d2_stage;
    
    // b0信号的扇出缓冲寄存器组
    reg b0_buf1, b0_buf2, b0_buf3, b0_buf4;
    
    // b0信号缓冲寄存器更新 - 实现扇出缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            b0_buf3 <= 1'b0;
            b0_buf4 <= 1'b0;
        end
        else begin
            b0_buf1 <= b0;
            b0_buf2 <= b0;
            b0_buf3 <= b0;
            b0_buf4 <= b0;
        end
    end
    
    // 第一级数据流水线 - 使用缓冲后的b0信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1_stage <= 1'b0;
            d2_stage <= 1'b0;
        end
        else if (b0_buf1) begin
            d1_stage <= d1;
            d2_stage <= d2;
        end
    end
    
    // 第二级数据流水线 - 使用不同的b0缓冲以平衡负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end
        else if (b0_buf2) begin
            q1 <= d1_stage & b0_buf3;
            q2 <= d2_stage & b0_buf4;
        end
    end
endmodule