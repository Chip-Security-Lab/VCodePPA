//SystemVerilog
module masked_buffer (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire [15:0] mask,
    input wire write_en,
    input wire valid_in,
    output wire valid_out,
    output wire ready_in,
    output reg [15:0] data_out
);
    // 前向重定时：直接计算组合逻辑，减少第一级寄存器前的延迟
    wire [15:0] masked_data_comb;
    wire [15:0] inverted_mask_comb;
    wire [15:0] preserved_data_comb;
    
    // 组合逻辑计算
    assign masked_data_comb = data_in & mask;
    assign inverted_mask_comb = ~mask;
    assign preserved_data_comb = data_out;
    
    // 阶段1: 存储组合逻辑结果
    reg [15:0] masked_data_stage1;
    reg [15:0] inverted_mask_stage1;
    reg [15:0] preserved_data_stage1;
    reg write_en_stage1;
    reg valid_stage1;
    
    // 阶段2: 最终合并
    reg [15:0] merged_data_stage2;
    reg valid_stage2;
    
    // 流水线控制信号
    assign ready_in = 1'b1; // 此设计始终可接收新数据
    assign valid_out = valid_stage2;
    
    // 阶段1: 寄存已计算的组合逻辑结果
    always @(posedge clk) begin
        if (rst) begin
            masked_data_stage1 <= 16'b0;
            inverted_mask_stage1 <= 16'b0;
            preserved_data_stage1 <= 16'b0;
            write_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end 
        else begin
            masked_data_stage1 <= masked_data_comb;
            inverted_mask_stage1 <= inverted_mask_comb;
            preserved_data_stage1 <= preserved_data_comb;
            write_en_stage1 <= write_en;
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2: 合并数据
    always @(posedge clk) begin
        if (rst) begin
            merged_data_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end 
        else begin
            if (write_en_stage1) begin
                merged_data_stage2 <= masked_data_stage1 | (preserved_data_stage1 & inverted_mask_stage1);
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'b0;
        end 
        else if (valid_stage2) begin
            data_out <= merged_data_stage2;
        end
    end
    
endmodule