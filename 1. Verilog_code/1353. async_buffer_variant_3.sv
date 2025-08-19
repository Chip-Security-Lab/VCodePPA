//SystemVerilog
module async_buffer (
    input wire clk,              // 添加时钟信号用于流水线寄存器
    input wire rst_n,            // 添加复位信号
    input wire [15:0] data_in,   // 输入数据
    input wire enable,           // 使能信号
    output reg [15:0] data_out   // 输出数据
);
    // 数据流分段定义
    reg [15:0] data_stage1;      // 第一级流水线寄存器
    reg enable_stage1;           // 使能信号流水线寄存器
    
    // 第一级流水线：捕获输入数据和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 16'b0;
            enable_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            enable_stage1 <= enable;
        end
    end
    
    // 第二级流水线：根据使能信号处理数据并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
        end else begin
            data_out <= enable_stage1 ? data_stage1 : 16'b0;
        end
    end
    
endmodule