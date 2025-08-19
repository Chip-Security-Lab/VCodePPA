//SystemVerilog
module masked_buffer (
    input wire clk,
    input wire rst_n,      // 添加复位信号
    input wire [15:0] data_in,
    input wire [15:0] mask,
    input wire write_en,
    input wire valid_in,   // 输入有效信号
    output wire ready_out, // 准备接收信号
    output reg [15:0] data_out,
    output reg valid_out   // 输出有效信号
);
    // 流水线阶段1寄存器
    reg [15:0] data_in_stage1;
    reg [15:0] mask_stage1;
    reg write_en_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg [15:0] masked_data_stage2;
    reg [15:0] inverted_mask_stage2;
    reg write_en_stage2;
    reg valid_stage2;
    
    // 流水线控制逻辑
    assign ready_out = 1'b1; // 始终准备接收新数据
    
    // 第一级流水线：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 16'b0;
            mask_stage1 <= 16'b0;
            write_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            mask_stage1 <= mask;
            write_en_stage1 <= write_en;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：计算掩码结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_stage2 <= 16'b0;
            inverted_mask_stage2 <= 16'b0;
            write_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            masked_data_stage2 <= data_in_stage1 & mask_stage1;
            inverted_mask_stage2 <= ~mask_stage1;
            write_en_stage2 <= write_en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            if (write_en_stage2) begin
                data_out <= masked_data_stage2 | (data_out & inverted_mask_stage2);
            end
            valid_out <= valid_stage2;
        end
    end
endmodule