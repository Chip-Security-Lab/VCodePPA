//SystemVerilog
//
// Conditional NAND module with optimized pipelined data path using forward register retiming
//
module Cond_NAND (
    input wire clk,          // 系统时钟
    input wire rst_n,        // 低电平有效复位
    input wire sel,          // 操作选择信号
    input wire [3:0] mask,   // 掩码输入
    input wire [3:0] data_in, // 数据输入
    output reg [3:0] data_out // 数据输出
);
    // 移动后的流水线寄存器
    reg sel_r1, sel_r2;
    reg [3:0] mask_r;
    reg [3:0] data_in_r1, data_in_r2;
    reg [3:0] nand_result;
    
    // 组合逻辑 - 在寄存前先计算NAND结果
    wire [3:0] nand_temp;
    assign nand_temp = ~(data_in & mask);
    
    // 第一级流水线 - 存储已计算的NAND结果和输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_r1 <= 1'b0;
            data_in_r1 <= 4'b0000;
            nand_result <= 4'b0000;
        end else begin
            sel_r1 <= sel;
            data_in_r1 <= data_in;
            nand_result <= nand_temp;
        end
    end
    
    // 第二级流水线 - 继续向前传递控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_r2 <= 1'b0;
            data_in_r2 <= 4'b0000;
        end else begin
            sel_r2 <= sel_r1;
            data_in_r2 <= data_in_r1;
        end
    end
    
    // 第三级流水线 - 输出多路复用
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 4'b0000;
        end else begin
            data_out <= sel_r2 ? nand_result : data_in_r2;
        end
    end

endmodule