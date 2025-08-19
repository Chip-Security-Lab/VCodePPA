//SystemVerilog
module DebugNOT(
    input wire clk,        // 添加时钟信号
    input wire rst_n,      // 添加复位信号
    input wire [7:0] data, // 输入数据
    output reg [7:0] inverse, // 改为寄存器输出
    output reg parity      // 改为寄存器输出
);
    // 创建流水线寄存器来分割数据路径
    reg [7:0] data_stage1;
    reg [7:0] inverse_stage1;
    reg parity_stage1;
    
    // 第一级流水线 - 注册输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'h00;
        end else begin
            data_stage1 <= data;
        end
    end
    
    // 第二级流水线 - 计算反转值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverse_stage1 <= 8'h00;
        end else begin
            inverse_stage1 <= ~data_stage1;
        end
    end
    
    // 第三级流水线 - 计算奇偶校验位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_stage1 <= 1'b0;
        end else begin
            parity_stage1 <= ~(^data_stage1);
        end
    end
    
    // 输出级 - 注册最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverse <= 8'h00;
            parity <= 1'b0;
        end else begin
            inverse <= inverse_stage1;
            parity <= parity_stage1;
        end
    end
endmodule