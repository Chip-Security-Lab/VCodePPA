//SystemVerilog
module Cond_NAND(
    input wire clk,          // 添加时钟信号用于流水线寄存器
    input wire rst_n,        // 添加复位信号
    input wire sel,
    input wire [3:0] mask, 
    input wire [3:0] data_in,
    output reg [3:0] data_out
);

    // Stage 1: 数据准备阶段
    reg [3:0] data_stage1;
    reg [3:0] mask_stage1;
    reg sel_stage1;
    
    // Stage 2: 掩码与操作阶段
    reg [3:0] masked_data;
    reg sel_stage2;
    
    // Stage 3: 条件取反阶段
    reg [3:0] inverted_data;
    reg sel_stage3;
    
    // 流水线寄存器 - 阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0;
            mask_stage1 <= 4'b0;
            sel_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            mask_stage1 <= mask;
            sel_stage1 <= sel;
        end
    end
    
    // 流水线寄存器 - 阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data <= 4'b0;
            sel_stage2 <= 1'b0;
        end else begin
            masked_data <= data_stage1 & mask_stage1;
            sel_stage2 <= sel_stage1;
        end
    end
    
    // 流水线寄存器 - 阶段3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_data <= 4'b0;
            sel_stage3 <= 1'b0;
        end else begin
            inverted_data <= ~masked_data;
            sel_stage3 <= sel_stage2;
        end
    end
    
    // 输出阶段 - 条件选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 4'b0;
        end else begin
            data_out <= sel_stage3 ? inverted_data : data_stage1;
        end
    end

endmodule