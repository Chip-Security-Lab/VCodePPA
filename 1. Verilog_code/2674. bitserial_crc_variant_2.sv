//SystemVerilog
module bitserial_crc(
    input wire clk,
    input wire rst,
    input wire bit_in,
    input wire bit_valid,
    output reg [7:0] crc8_out
);
    parameter CRC_POLY = 8'h07; // x^8 + x^2 + x + 1
    
    // 流水线阶段1：输入处理和初始反馈计算
    reg feedback_stage1;
    reg [7:0] crc8_stage1;
    reg valid_stage1;
    
    // 流水线阶段2：左移操作
    reg feedback_stage2;
    reg [7:0] crc8_stage2;
    reg valid_stage2;
    
    // 流水线阶段3：多项式选择
    reg [7:0] crc8_stage3;
    reg [7:0] poly_xor_stage3;
    reg valid_stage3;
    
    // 流水线阶段4：部分异或计算 (高4位)
    reg [3:0] crc8_high_stage4;
    reg [3:0] poly_high_stage4;
    reg [3:0] crc8_low_stage4;
    reg [3:0] poly_low_stage4;
    reg valid_stage4;
    
    // 流水线阶段5：部分异或计算 (低4位) 和最终合并
    reg [3:0] crc8_high_stage5;
    reg [3:0] crc8_low_stage5;
    reg valid_stage5;
    
    // 阶段1：计算反馈
    always @(posedge clk) begin
        if (rst) begin
            feedback_stage1 <= 1'b0;
            crc8_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= bit_valid;
            if (bit_valid) begin
                feedback_stage1 <= crc8_out[7] ^ bit_in;
                crc8_stage1 <= crc8_out;
            end
        end
    end
    
    // 阶段2：左移操作
    always @(posedge clk) begin
        if (rst) begin
            feedback_stage2 <= 1'b0;
            crc8_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                feedback_stage2 <= feedback_stage1;
                crc8_stage2 <= {crc8_stage1[6:0], 1'b0};
            end
        end
    end
    
    // 阶段3：多项式选择
    always @(posedge clk) begin
        if (rst) begin
            crc8_stage3 <= 8'h00;
            poly_xor_stage3 <= 8'h00;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                crc8_stage3 <= crc8_stage2;
                poly_xor_stage3 <= feedback_stage2 ? CRC_POLY : 8'h00;
            end
        end
    end
    
    // 阶段4：部分异或计算 (拆分高4位和低4位)
    always @(posedge clk) begin
        if (rst) begin
            crc8_high_stage4 <= 4'h0;
            poly_high_stage4 <= 4'h0;
            crc8_low_stage4 <= 4'h0;
            poly_low_stage4 <= 4'h0;
            valid_stage4 <= 1'b0;
        end else begin
            valid_stage4 <= valid_stage3;
            if (valid_stage3) begin
                crc8_high_stage4 <= crc8_stage3[7:4];
                poly_high_stage4 <= poly_xor_stage3[7:4];
                crc8_low_stage4 <= crc8_stage3[3:0];
                poly_low_stage4 <= poly_xor_stage3[3:0];
            end
        end
    end
    
    // 阶段5：完成异或计算并合并结果
    always @(posedge clk) begin
        if (rst) begin
            crc8_high_stage5 <= 4'h0;
            crc8_low_stage5 <= 4'h0;
            valid_stage5 <= 1'b0;
        end else begin
            valid_stage5 <= valid_stage4;
            if (valid_stage4) begin
                crc8_high_stage5 <= crc8_high_stage4 ^ poly_high_stage4;
                crc8_low_stage5 <= crc8_low_stage4 ^ poly_low_stage4;
            end
        end
    end
    
    // 最终CRC输出
    always @(posedge clk) begin
        if (rst) begin
            crc8_out <= 8'h00;
        end else if (valid_stage5) begin
            crc8_out <= {crc8_high_stage5, crc8_low_stage5};
        end
    end
endmodule