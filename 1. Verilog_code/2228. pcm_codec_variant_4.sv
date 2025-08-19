//SystemVerilog
`timescale 1ns / 1ps

module pcm_codec #(parameter DATA_WIDTH = 16)
(
    input wire clk, rst_n, 
    input wire [DATA_WIDTH-1:0] pcm_in,     // PCM input samples
    input wire [7:0] compressed_in,         // Compressed input
    input wire encode_mode,                 // 1=encode, 0=decode
    output reg [7:0] compressed_out,        // Compressed output
    output reg [DATA_WIDTH-1:0] pcm_out,    // PCM output samples
    output reg data_valid
);
    // μ-law compression constants
    localparam BIAS = 33;
    localparam SEG_SHIFT = 4;
    
    // 输入信号缓冲，减少高扇出
    reg [DATA_WIDTH-1:0] pcm_in_buf1;
    reg [DATA_WIDTH-1:0] pcm_in_buf2;
    reg encode_mode_r1, encode_mode_r2, encode_mode_r3;
    reg [7:0] compressed_in_r1, compressed_in_r2;
    
    // 流水线寄存器
    reg [DATA_WIDTH-1:0] abs_sample_stage1;
    reg [DATA_WIDTH-1:0] abs_sample_stage2;
    reg [DATA_WIDTH-1:0] abs_sample_stage3;
    reg sign_stage1, sign_stage2, sign_stage3;
    reg [3:0] segment_stage1;
    reg [3:0] segment_stage2;
    reg [3:0] segment_stage3;
    reg data_valid_stage1, data_valid_stage2, data_valid_stage3;
    
    // 编码中间结果寄存器
    reg [7:0] encoded_result_stage1;
    reg [7:0] encoded_result_stage2;
    
    // 解码中间结果寄存器
    reg [DATA_WIDTH-1:0] decoded_partial_stage1;
    reg [DATA_WIDTH-1:0] decoded_partial_stage2;
    reg [DATA_WIDTH-1:0] decoded_result;
    
    // 多级缓冲结构，分散驱动负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pcm_in_buf1 <= {DATA_WIDTH{1'b0}};
            pcm_in_buf2 <= {DATA_WIDTH{1'b0}};
            encode_mode_r1 <= 1'b0;
            encode_mode_r2 <= 1'b0;
            encode_mode_r3 <= 1'b0;
            compressed_in_r1 <= 8'h00;
            compressed_in_r2 <= 8'h00;
        end else begin
            pcm_in_buf1 <= pcm_in;
            pcm_in_buf2 <= pcm_in_buf1;
            encode_mode_r1 <= encode_mode;
            encode_mode_r2 <= encode_mode_r1;
            encode_mode_r3 <= encode_mode_r2;
            compressed_in_r1 <= compressed_in;
            compressed_in_r2 <= compressed_in_r1;
        end
    end
    
    // 第一级流水线 - 计算绝对值和符号位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage1 <= {DATA_WIDTH{1'b0}};
            sign_stage1 <= 1'b0;
            data_valid_stage1 <= 1'b0;
        end else if (encode_mode_r1) begin
            sign_stage1 <= pcm_in_buf1[DATA_WIDTH-1];
            abs_sample_stage1 <= pcm_in_buf1[DATA_WIDTH-1] ? (~pcm_in_buf1 + 1'b1) : pcm_in_buf1;
            data_valid_stage1 <= 1'b1;
        end else begin
            // 解码预处理
            sign_stage1 <= compressed_in_r1[7];
            abs_sample_stage1 <= {{(DATA_WIDTH-8){1'b0}}, compressed_in_r1};
            data_valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线 - 段确定和初步处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage2 <= {DATA_WIDTH{1'b0}};
            sign_stage2 <= 1'b0;
            segment_stage1 <= 4'b0000;
            data_valid_stage2 <= 1'b0;
            decoded_partial_stage1 <= {DATA_WIDTH{1'b0}};
        end else begin
            abs_sample_stage2 <= abs_sample_stage1;
            sign_stage2 <= sign_stage1;
            data_valid_stage2 <= data_valid_stage1;
            
            if (encode_mode_r2) begin
                // 计算段落 - 将长计算路径切割
                if (abs_sample_stage1 < 16) 
                    segment_stage1 <= 4'd0;
                else if (abs_sample_stage1 < 32) 
                    segment_stage1 <= 4'd1;
                else if (abs_sample_stage1 < 64) 
                    segment_stage1 <= 4'd2;
                else if (abs_sample_stage1 < 128) 
                    segment_stage1 <= 4'd3;
                else if (abs_sample_stage1 < 256) 
                    segment_stage1 <= 4'd4;
                else if (abs_sample_stage1 < 512) 
                    segment_stage1 <= 4'd5;
                else if (abs_sample_stage1 < 1024) 
                    segment_stage1 <= 4'd6;
                else 
                    segment_stage1 <= 4'd7;
            end else begin
                // 解码过程第一阶段 - 提取段和偏移
                segment_stage1 <= abs_sample_stage1[6:4];
                
                // 第一级解码 - 准备基础值
                case (abs_sample_stage1[6:4])
                    3'd0: decoded_partial_stage1 <= {4'b0, abs_sample_stage1[3:0], 4'b0000};
                    3'd1: decoded_partial_stage1 <= {3'b0, abs_sample_stage1[3:0], 5'b00000};
                    3'd2: decoded_partial_stage1 <= {2'b0, abs_sample_stage1[3:0], 6'b000000};
                    3'd3: decoded_partial_stage1 <= {1'b0, abs_sample_stage1[3:0], 7'b0000000};
                    default: decoded_partial_stage1 <= 16'd4095;
                endcase
            end
        end
    end
    
    // 第三级流水线 - 完成编码/解码第二阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage3 <= {DATA_WIDTH{1'b0}};
            sign_stage3 <= 1'b0;
            segment_stage2 <= 4'b0000;
            data_valid_stage3 <= 1'b0;
            encoded_result_stage1 <= 8'h00;
            decoded_partial_stage2 <= {DATA_WIDTH{1'b0}};
        end else begin
            abs_sample_stage3 <= abs_sample_stage2;
            sign_stage3 <= sign_stage2;
            segment_stage2 <= segment_stage1;
            data_valid_stage3 <= data_valid_stage2;
            
            if (encode_mode_r2) begin
                // 基于段落计算编码值
                encoded_result_stage1 <= {sign_stage2, segment_stage1, 
                                        abs_sample_stage2[3:0] & ({4{segment_stage1 != 4'd0}})};
            end else begin
                // 解码过程第二阶段 - 添加偏移量
                case (segment_stage1)
                    3'd0: decoded_partial_stage2 <= decoded_partial_stage1;
                    3'd1: decoded_partial_stage2 <= decoded_partial_stage1 + 16'd256;
                    3'd2: decoded_partial_stage2 <= decoded_partial_stage1 + 16'd768;
                    3'd3: decoded_partial_stage2 <= decoded_partial_stage1 + 16'd1792;
                    default: decoded_partial_stage2 <= decoded_partial_stage1;
                endcase
            end
        end
    end
    
    // 第四级流水线 - 最终计算和输出准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            segment_stage3 <= 4'b0000;
            encoded_result_stage2 <= 8'h00;
            decoded_result <= {DATA_WIDTH{1'b0}};
        end else begin
            segment_stage3 <= segment_stage2;
            
            if (encode_mode_r3) begin
                encoded_result_stage2 <= encoded_result_stage1;
            end else begin
                // 解码过程最终阶段 - 应用符号
                if (sign_stage3)
                    decoded_result <= {1'b1, {(DATA_WIDTH-1){1'b0}}} - decoded_partial_stage2;
                else
                    decoded_result <= decoded_partial_stage2;
            end
        end
    end
    
    // 输出寄存器 - 最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compressed_out <= 8'h00;
            pcm_out <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            data_valid <= data_valid_stage3;
            if (encode_mode_r3) begin
                compressed_out <= encoded_result_stage2;
                pcm_out <= pcm_out; // 保持不变
            end else begin
                compressed_out <= compressed_out; // 保持不变
                pcm_out <= decoded_result;
            end
        end
    end
endmodule