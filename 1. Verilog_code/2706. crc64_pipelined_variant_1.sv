//SystemVerilog
module crc64_pipelined (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [63:0] data_in,
    output wire valid_out,
    output wire [63:0] crc_out,
    output wire ready
);
    parameter POLY = 64'h42F0E1EBA9EA3693;
    
    // 流水线寄存器
    reg [63:0] data_stage1, data_stage2, data_stage3, data_stage4;
    reg [63:0] crc_stage1, crc_stage2, crc_stage3, crc_stage4;
    
    // 控制信号流水线
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // CRC计算中间结果
    wire [63:0] xor_result_stage1, xor_result_stage2, xor_result_stage3, xor_result_stage4;
    wire [63:0] poly_masked_stage1, poly_masked_stage2, poly_masked_stage3, poly_masked_stage4;
    
    // 第一级计算
    assign poly_masked_stage1 = {64{data_in[63]}} & POLY;
    assign xor_result_stage1 = data_in ^ (data_in[63] ? POLY : 64'h0);
    
    // 第二级计算
    assign poly_masked_stage2 = {64{data_stage1[62]}} & POLY;
    assign xor_result_stage2 = {data_stage1[62:0], 1'b0} ^ (data_stage1[62] ? POLY : 64'h0);
    
    // 第三级计算
    assign poly_masked_stage3 = {64{data_stage2[61]}} & POLY;
    assign xor_result_stage3 = {data_stage2[61:0], 2'b0} ^ (data_stage2[61] ? POLY : 64'h0);
    
    // 第四级计算
    assign poly_masked_stage4 = {64{data_stage3[60]}} & POLY;
    assign xor_result_stage4 = {data_stage3[60:0], 3'b0} ^ (data_stage3[60] ? POLY : 64'h0);
    
    // 输出赋值
    assign crc_out = crc_stage4;
    assign valid_out = valid_stage4;
    assign ready = 1'b1; // 此流水线始终准备接收新数据
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            data_stage1 <= 64'h0;
            data_stage2 <= 64'h0;
            data_stage3 <= 64'h0;
            data_stage4 <= 64'h0;
            
            crc_stage1 <= 64'h0;
            crc_stage2 <= 64'h0;
            crc_stage3 <= 64'h0;
            crc_stage4 <= 64'h0;
            
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
        end
        else begin
            // 第一级流水线
            if (valid_in) begin
                data_stage1 <= data_in;
                crc_stage1 <= xor_result_stage1;
                valid_stage1 <= 1'b1;
            end
            else if (valid_stage1) begin
                valid_stage1 <= 1'b0;
            end
            
            // 第二级流水线
            data_stage2 <= data_stage1;
            crc_stage2 <= crc_stage1 ^ xor_result_stage2;
            valid_stage2 <= valid_stage1;
            
            // 第三级流水线
            data_stage3 <= data_stage2;
            crc_stage3 <= crc_stage2 ^ xor_result_stage3;
            valid_stage3 <= valid_stage2;
            
            // 第四级流水线
            data_stage4 <= data_stage3;
            crc_stage4 <= crc_stage3 ^ xor_result_stage4;
            valid_stage4 <= valid_stage3;
        end
    end
    
endmodule