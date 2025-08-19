//SystemVerilog
module crc_galois (
    input clk, rst_n,
    input valid_in,         // 输入数据有效信号
    input [7:0] data,
    output reg valid_out,   // 输出数据有效信号
    output reg [7:0] crc
);
    parameter POLY = 8'hD5;
    
    // 流水线阶段1：处理比特0-1
    reg [7:0] stage1_data;
    reg [7:0] stage1_crc;
    reg stage1_valid;
    
    wire [7:0] xord = stage1_crc ^ stage1_data;
    wire [7:0] bit0 = {xord[6:0], 1'b0} ^ (xord[7] ? POLY : 0);
    wire [7:0] bit1 = {bit0[6:0], 1'b0} ^ (bit0[7] ? POLY : 0);
    
    // 流水线阶段2：处理比特2-3
    reg [7:0] stage2_data;
    reg stage2_valid;
    
    wire [7:0] bit2 = {stage2_data[6:0], 1'b0} ^ (stage2_data[7] ? POLY : 0);
    wire [7:0] bit3 = {bit2[6:0], 1'b0} ^ (bit2[7] ? POLY : 0);
    
    // 流水线阶段3：处理比特4-5
    reg [7:0] stage3_data;
    reg stage3_valid;
    
    wire [7:0] bit4 = {stage3_data[6:0], 1'b0} ^ (stage3_data[7] ? POLY : 0);
    wire [7:0] bit5 = {bit4[6:0], 1'b0} ^ (bit4[7] ? POLY : 0);
    
    // 流水线阶段4：处理比特6-7
    reg [7:0] stage4_data;
    reg stage4_valid;
    
    wire [7:0] bit6 = {stage4_data[6:0], 1'b0} ^ (stage4_data[7] ? POLY : 0);
    wire [7:0] bit7 = {bit6[6:0], 1'b0} ^ (bit6[7] ? POLY : 0);
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            stage1_data <= 8'h00;
            stage1_crc <= 8'h00;
            stage1_valid <= 1'b0;
            
            stage2_data <= 8'h00;
            stage2_valid <= 1'b0;
            
            stage3_data <= 8'h00;
            stage3_valid <= 1'b0;
            
            stage4_data <= 8'h00;
            stage4_valid <= 1'b0;
            
            valid_out <= 1'b0;
            crc <= 8'h00;
        end
        else begin
            // 第一阶段 - 接收输入数据
            stage1_data <= data;
            stage1_crc <= crc;
            stage1_valid <= valid_in;
            
            // 第二阶段 - 处理bit0-1的结果
            stage2_data <= bit1;
            stage2_valid <= stage1_valid;
            
            // 第三阶段 - 处理bit2-3的结果
            stage3_data <= bit3;
            stage3_valid <= stage2_valid;
            
            // 第四阶段 - 处理bit4-5的结果
            stage4_data <= bit5;
            stage4_valid <= stage3_valid;
            
            // 最终输出 - 处理bit6-7并更新CRC
            crc <= bit7;
            valid_out <= stage4_valid;
        end
    end
endmodule