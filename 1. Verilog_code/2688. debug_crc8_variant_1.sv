//SystemVerilog
module debug_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire valid,
    output reg [7:0] crc_out,
    output reg error_detected,
    output reg [3:0] bit_position,
    output reg processing_active
);
    parameter [7:0] POLY = 8'h07;
    
    // 增加更多的流水线寄存器，将CRC计算分为多个阶段
    reg [7:0] crc_stage1, crc_stage2, crc_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [3:0] bit_pos_stage1, bit_pos_stage2, bit_pos_stage3;
    reg proc_active_stage1, proc_active_stage2, proc_active_stage3;
    
    // 将CRC计算分解为多个阶段
    // 阶段1: 计算XOR条件和掩码
    reg crc_msb_xor_data_stage1;
    reg [7:0] poly_mask_stage1;
    
    // 阶段2: 计算移位和XOR操作
    reg [7:0] shifted_crc_stage2;
    reg [7:0] next_crc_stage2;
    
    // 阶段3: 更新CRC和检查错误条件
    reg error_condition_stage3;
    
    // 阶段1: 计算初始XOR和掩码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage1 <= 8'h00;
            crc_msb_xor_data_stage1 <= 1'b0;
            poly_mask_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
            bit_pos_stage1 <= 4'd0;
            proc_active_stage1 <= 1'b0;
        end else begin
            crc_stage1 <= crc_out;
            crc_msb_xor_data_stage1 <= crc_out[7] ^ data[0];
            poly_mask_stage1 <= (crc_out[7] ^ data[0]) ? POLY : 8'h0;
            valid_stage1 <= valid;
            bit_pos_stage1 <= valid ? (bit_position + 1) : bit_position;
            proc_active_stage1 <= valid ? 1'b1 : 1'b0;
        end
    end
    
    // 阶段2: 计算CRC移位和XOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage2 <= 8'h00;
            shifted_crc_stage2 <= 8'h00;
            next_crc_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
            bit_pos_stage2 <= 4'd0;
            proc_active_stage2 <= 1'b0;
        end else begin
            crc_stage2 <= crc_stage1;
            shifted_crc_stage2 <= {crc_stage1[6:0], 1'b0};
            next_crc_stage2 <= {crc_stage1[6:0], 1'b0} ^ poly_mask_stage1;
            valid_stage2 <= valid_stage1;
            bit_pos_stage2 <= bit_pos_stage1;
            proc_active_stage2 <= proc_active_stage1;
        end
    end
    
    // 阶段3: 错误检测条件评估
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage3 <= 8'h00;
            error_condition_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            bit_pos_stage3 <= 4'd0;
            proc_active_stage3 <= 1'b0;
        end else begin
            crc_stage3 <= next_crc_stage2;
            error_condition_stage3 <= (crc_stage2 != 8'h00) && (bit_pos_stage2 == 4'd7);
            valid_stage3 <= valid_stage2;
            bit_pos_stage3 <= bit_pos_stage2;
            proc_active_stage3 <= proc_active_stage2;
        end
    end
    
    // 最终输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
            error_detected <= 1'b0;
            bit_position <= 4'd0;
            processing_active <= 1'b0;
        end else begin
            if (valid_stage3) begin
                crc_out <= crc_stage3;
                error_detected <= error_condition_stage3;
                bit_position <= bit_pos_stage3;
                processing_active <= proc_active_stage3;
            end else begin
                // 保持当前状态，但处理非活动状态
                crc_out <= crc_out;
                error_detected <= error_detected;
                bit_position <= bit_pos_stage3;
                processing_active <= proc_active_stage3;
            end
        end
    end
    
    // 额外的错误检测流水线，提高关键路径的时序性能
    reg error_detect_stage1, error_detect_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_detect_stage1 <= 1'b0;
            error_detect_stage2 <= 1'b0;
        end else begin
            error_detect_stage1 <= (crc_stage2 != 8'h00) && (bit_pos_stage2 == 4'd7);
            error_detect_stage2 <= error_detect_stage1;
        end
    end
endmodule