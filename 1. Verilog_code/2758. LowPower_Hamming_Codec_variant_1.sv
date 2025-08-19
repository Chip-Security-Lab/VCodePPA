//SystemVerilog
module LowPower_Hamming_Codec(
    input clk,
    input rst_n,
    input power_save_en,
    input [10:0] data_in,
    output reg [15:0] data_out
);
    // 使用专用时钟门控单元替代简单的AND门
    wire clk_en;
    wire gated_clk;
    
    // 寄存时钟使能信号，避免毛刺
    reg clk_en_latch;
    
    // 标准的时钟门控结构
    assign clk_en = ~power_save_en;
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_en_latch <= 1'b0;
        else
            clk_en_latch <= clk_en;
    end
    
    // 使用AND门实现时钟门控
    assign gated_clk = clk & clk_en_latch;
    
    // 内部信号声明 - 为高扇出信号添加缓冲寄存器
    reg [10:0] data_reg;
    reg [15:0] encoded_stage1, encoded_stage2;
    
    // 添加输入缓冲寄存器，降低data的扇出
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 11'b0;
        end else begin
            data_reg <= data_in;
        end
    end
    
    // 添加中间缓冲寄存器，分解编码计算步骤
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_stage1 <= 16'b0;
        end else begin
            // 第一阶段：数据位映射
            encoded_stage1[2] <= data_reg[0];
            encoded_stage1[4] <= data_reg[1];
            encoded_stage1[5] <= data_reg[2];
            encoded_stage1[6] <= data_reg[3];
            encoded_stage1[8] <= data_reg[4];
            encoded_stage1[9] <= data_reg[5];
            encoded_stage1[10] <= data_reg[6];
            encoded_stage1[11] <= data_reg[7];
            encoded_stage1[12] <= data_reg[8];
            encoded_stage1[13] <= data_reg[9];
            encoded_stage1[14] <= data_reg[10];
            encoded_stage1[0] <= 1'b0;
            encoded_stage1[1] <= 1'b0;
            encoded_stage1[3] <= 1'b0;
            encoded_stage1[7] <= 1'b0;
            encoded_stage1[15] <= 1'b0;
        end
    end
    
    // 奇偶校验位的缓冲寄存器
    reg p1_buf1, p1_buf2;
    reg p2_buf1, p2_buf2;
    reg p4_buf1, p4_buf2;
    reg p8_buf1, p8_buf2;
    
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位奇偶校验位缓冲器
            p1_buf1 <= 1'b0;
            p1_buf2 <= 1'b0;
            p2_buf1 <= 1'b0;
            p2_buf2 <= 1'b0;
            p4_buf1 <= 1'b0;
            p4_buf2 <= 1'b0;
            p8_buf1 <= 1'b0;
            p8_buf2 <= 1'b0;
            encoded_stage2 <= 16'b0;
        end else begin
            // 计算奇偶校验位并使用多级缓冲处理高扇出
            // 分割异或计算树，降低每个异或门的输入数量
            p1_buf1 <= encoded_stage1[2] ^ encoded_stage1[4] ^ encoded_stage1[6];
            p1_buf2 <= encoded_stage1[8] ^ encoded_stage1[10] ^ encoded_stage1[12] ^ encoded_stage1[14];
            
            p2_buf1 <= encoded_stage1[2] ^ encoded_stage1[5] ^ encoded_stage1[6];
            p2_buf2 <= encoded_stage1[9] ^ encoded_stage1[10] ^ encoded_stage1[13] ^ encoded_stage1[14];
            
            p4_buf1 <= encoded_stage1[4] ^ encoded_stage1[5] ^ encoded_stage1[6];
            p4_buf2 <= encoded_stage1[11] ^ encoded_stage1[12] ^ encoded_stage1[13] ^ encoded_stage1[14];
            
            p8_buf1 <= encoded_stage1[8] ^ encoded_stage1[9] ^ encoded_stage1[10];
            p8_buf2 <= encoded_stage1[11] ^ encoded_stage1[12] ^ encoded_stage1[13] ^ encoded_stage1[14];
            
            // 将数据位复制到第二阶段
            encoded_stage2 <= encoded_stage1;
        end
    end
    
    // 最终输出阶段 - 合并奇偶校验位结果
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
        end else begin
            // 复制数据位
            data_out <= encoded_stage2;
            
            // 合并最终奇偶校验位
            data_out[1] <= p1_buf1 ^ p1_buf2;
            data_out[3] <= p2_buf1 ^ p2_buf2;
            data_out[7] <= p4_buf1 ^ p4_buf2;
            data_out[15] <= p8_buf1 ^ p8_buf2;
            
            // 计算整体奇偶校验位
            // 使用中间结果减少最终异或门的负载
            data_out[0] <= (p1_buf1 ^ p1_buf2) ^ (p2_buf1 ^ p2_buf2) ^ 
                           (p4_buf1 ^ p4_buf2) ^ (p8_buf1 ^ p8_buf2) ^ 
                           (^encoded_stage2[14:2]);
        end
    end
endmodule