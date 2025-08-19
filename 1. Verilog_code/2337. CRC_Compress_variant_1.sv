//SystemVerilog
module CRC_Compress #(
    parameter POLY = 32'h04C11DB7
) (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire en,
    input wire [31:0] data,
    input wire valid_in,  // 输入数据有效信号
    output wire valid_out, // 输出数据有效信号
    output wire [31:0] crc
);

    // 流水线寄存器
    reg [31:0] data_stage1, data_stage2, data_stage3, data_stage4;
    reg [31:0] crc_stage1, crc_stage2, crc_stage3, crc_stage4, crc_stage5;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    
    // 流水线中间结果寄存器
    reg [7:0] partial_result_stage1, partial_result_stage2, partial_result_stage3, partial_result_stage4;
    
    // 输出赋值
    assign crc = crc_stage5;
    assign valid_out = valid_stage5;
    
    // 第一级流水线 - 处理前8位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 32'h0;
            crc_stage1 <= 32'h0;
            valid_stage1 <= 1'b0;
            partial_result_stage1 <= 8'h0;
        end else if (en) begin
            data_stage1 <= data;
            crc_stage1 <= crc_stage5; // 反馈最终结果
            valid_stage1 <= valid_in;
            
            // 处理前8位的CRC计算
            partial_result_stage1 <= process_bits(crc_stage5[31:24], data[31:24]);
        end
    end
    
    // 第二级流水线 - 处理接下来的8位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 32'h0;
            crc_stage2 <= 32'h0;
            valid_stage2 <= 1'b0;
            partial_result_stage2 <= 8'h0;
        end else if (en) begin
            data_stage2 <= data_stage1;
            crc_stage2 <= {crc_stage1[23:0], partial_result_stage1};
            valid_stage2 <= valid_stage1;
            
            // 处理接下来8位的CRC计算
            partial_result_stage2 <= process_bits(partial_result_stage1, data_stage1[23:16]);
        end
    end
    
    // 第三级流水线 - 处理再接下来的8位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 32'h0;
            crc_stage3 <= 32'h0;
            valid_stage3 <= 1'b0;
            partial_result_stage3 <= 8'h0;
        end else if (en) begin
            data_stage3 <= data_stage2;
            crc_stage3 <= {crc_stage2[23:0], partial_result_stage2};
            valid_stage3 <= valid_stage2;
            
            // 处理再接下来8位的CRC计算
            partial_result_stage3 <= process_bits(partial_result_stage2, data_stage2[15:8]);
        end
    end
    
    // 第四级流水线 - 处理最后8位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage4 <= 32'h0;
            crc_stage4 <= 32'h0;
            valid_stage4 <= 1'b0;
            partial_result_stage4 <= 8'h0;
        end else if (en) begin
            data_stage4 <= data_stage3;
            crc_stage4 <= {crc_stage3[23:0], partial_result_stage3};
            valid_stage4 <= valid_stage3;
            
            // 处理最后8位的CRC计算
            partial_result_stage4 <= process_bits(partial_result_stage3, data_stage3[7:0]);
        end
    end
    
    // 第五级流水线 - 最终结果整合
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage5 <= 32'h0;
            valid_stage5 <= 1'b0;
        end else if (en) begin
            crc_stage5 <= {crc_stage4[23:0], partial_result_stage4};
            valid_stage5 <= valid_stage4;
        end
    end
    
    // 辅助函数：处理CRC位计算
    function [7:0] process_bits;
        input [7:0] crc_in;
        input [7:0] data_in;
        reg [7:0] result;
        integer i;
        begin
            result = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                if (result[7] ^ data_in[7-i]) begin
                    result = {result[6:0], 1'b0} ^ POLY[31:24];
                end else begin
                    result = {result[6:0], 1'b0};
                end
            end
            process_bits = result;
        end
    endfunction

endmodule